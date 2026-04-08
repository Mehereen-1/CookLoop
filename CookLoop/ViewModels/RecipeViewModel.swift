//
//  RecipeViewModel.swift
//  CookLoop
//
//  Created by Ayesha Meherin on 27/3/26.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth

class RecipeViewModel: ObservableObject {

    @Published var isUploading = false
    @Published var errorMessage = ""
    @Published var recipes: [Recipe] = []
    @Published var likesByRecipeId: [String: Bool] = [:]
    
    private let db = Firestore.firestore()
    
    func uploadRecipe(
        title: String,
        ingredients: [String],
        steps: [String],
        imageUrl: String,
        completion: ((Bool) -> Void)? = nil
    ) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanedTitle.isEmpty else {
            errorMessage = "Please enter a recipe title."
            completion?(false)
            return
        }
        
        isUploading = true
        errorMessage = ""
        let recipeId = UUID().uuidString
        
        let data: [String: Any] = [
            "id": recipeId,
            "userId": uid,
            "title": cleanedTitle,
            "imageUrl": imageUrl.trimmingCharacters(in: .whitespacesAndNewlines),
            "ingredients": ingredients,
            "steps": steps,
            "likes": 0,
            "createdAt": Timestamp(date: Date())
        ]
        
        db.collection("recipes").document(recipeId).setData(data) { error in
            DispatchQueue.main.async {
                self.isUploading = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    completion?(false)
                    return
                }

                self.fetchRecipes()
                completion?(true)
            }
        }
    }

    func fetchRecipes() {
        db.collection("recipes")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        return
                    }

                    let fetchedRecipes: [Recipe] = snapshot?.documents.compactMap { doc in
                        Self.parseRecipe(id: doc.documentID, data: doc.data())
                    } ?? []

                    self.recipes = fetchedRecipes
                    self.fetchLikeStateForCurrentUser()
                }
            }
    }

    func toggleLike(for recipe: Recipe) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let recipeRef = db.collection("recipes").document(recipe.id)
        let likeRef = recipeRef.collection("likes").document(uid)

        likeRef.getDocument { snapshot, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
                return
            }

            let alreadyLiked = snapshot?.exists ?? false
            let batch = self.db.batch()

            if alreadyLiked {
                batch.deleteDocument(likeRef)
                batch.updateData(["likes": FieldValue.increment(Int64(-1))], forDocument: recipeRef)
            } else {
                batch.setData(["createdAt": Timestamp(date: Date())], forDocument: likeRef)
                batch.updateData(["likes": FieldValue.increment(Int64(1))], forDocument: recipeRef)
            }

            batch.commit { batchError in
                DispatchQueue.main.async {
                    if let batchError = batchError {
                        self.errorMessage = batchError.localizedDescription
                        return
                    }

                    self.likesByRecipeId[recipe.id] = !alreadyLiked
                    if let index = self.recipes.firstIndex(where: { $0.id == recipe.id }) {
                        let delta = alreadyLiked ? -1 : 1
                        self.recipes[index].likes = max(0, self.recipes[index].likes + delta)
                    }
                }
            }
        }
    }

    private func fetchLikeStateForCurrentUser() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        for recipe in recipes {
            db.collection("recipes")
                .document(recipe.id)
                .collection("likes")
                .document(uid)
                .getDocument { snapshot, _ in
                    DispatchQueue.main.async {
                        self.likesByRecipeId[recipe.id] = snapshot?.exists ?? false
                    }
                }
        }
    }

    static func parseRecipe(id: String, data: [String: Any]) -> Recipe? {
        let createdAtTimestamp = data["createdAt"] as? Timestamp
        let legacyTimestamp = data["timestamp"] as? Timestamp
        let createdAt = createdAtTimestamp?.dateValue() ?? legacyTimestamp?.dateValue() ?? Date()

        return Recipe(
            id: id,
            userId: data["userId"] as? String ?? "",
            title: data["title"] as? String ?? "Untitled Recipe",
            imageUrl: data["imageUrl"] as? String ?? "",
            legacyImageData: data["imageData"] as? String,
            ingredients: data["ingredients"] as? [String] ?? [],
            steps: data["steps"] as? [String] ?? [],
            likes: data["likes"] as? Int ?? 0,
            createdAt: createdAt
        )
    }
}
