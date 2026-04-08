//
//  RecipeDetailViewModel.swift
//  CookLoop
//
//  Created by GitHub Copilot on 7/4/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class RecipeDetailViewModel: ObservableObject {
    @Published var recipe: Recipe
    @Published var isLiked: Bool = false
    @Published var creatorName: String = "Cook"
    @Published var errorMessage: String = ""

    private let db = Firestore.firestore()

    init(recipe: Recipe) {
        self.recipe = recipe
    }

    func load() {
        fetchCreatorName()
        fetchLikeState()
    }

    func toggleLike() {
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

                    self.isLiked = !alreadyLiked
                    let delta = alreadyLiked ? -1 : 1
                    self.recipe.likes = max(0, self.recipe.likes + delta)
                }
            }
        }
    }

    private func fetchLikeState() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("recipes")
            .document(recipe.id)
            .collection("likes")
            .document(uid)
            .getDocument { snapshot, _ in
                DispatchQueue.main.async {
                    self.isLiked = snapshot?.exists ?? false
                }
            }
    }

    private func fetchCreatorName() {
        db.collection("users").document(recipe.userId).getDocument { snapshot, _ in
            guard let data = snapshot?.data() else { return }

            DispatchQueue.main.async {
                self.creatorName = data["name"] as? String ?? "Cook"
            }
        }
    }
}