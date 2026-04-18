//
//  BookmarkViewModel.swift
//  CookLoop
//
//  Created by GitHub Copilot on 7/4/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class BookmarkViewModel: ObservableObject {
    @Published var savedRecipeIds: Set<String> = []
    @Published var savedRecipes: [CookLoop.Recipe] = []
    @Published var errorMessage: String = ""

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    deinit {
        stopListening()
    }

    func startListening() {
        stopListening()

        guard let uid = Auth.auth().currentUser?.uid else {
            savedRecipeIds = []
            savedRecipes = []
            return
        }

        listener = db.collection("users")
            .document(uid)
            .collection("savedRecipes")
            .order(by: "savedAt", descending: true)
            .addSnapshotListener { snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        return
                    }

                    let ids = snapshot?.documents.map { $0.documentID } ?? []
                    self.savedRecipeIds = Set(ids)
                    self.fetchSavedRecipes(recipeIdsInOrder: ids)
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func isSaved(recipeId: String) -> Bool {
        savedRecipeIds.contains(recipeId)
    }

    func toggleSaved(recipe: CookLoop.Recipe) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        if isSaved(recipeId: recipe.id) {
            unsaveRecipe(recipeId: recipe.id, uid: uid)
        } else {
            saveRecipe(recipeId: recipe.id, uid: uid)
        }
    }

    private func saveRecipe(recipeId: String, uid: String) {
        let docRef = db.collection("users")
            .document(uid)
            .collection("savedRecipes")
            .document(recipeId)

        savedRecipeIds.insert(recipeId)

        docRef.setData([
            "recipeId": recipeId,
            "savedAt": Timestamp(date: Date())
        ]) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.savedRecipeIds.remove(recipeId)
                    self.errorMessage = error.localizedDescription
                } else {
                    GamificationService.shared.awardBookmark(userId: uid)
                }
            }
        }
    }

    private func unsaveRecipe(recipeId: String, uid: String) {
        let docRef = db.collection("users")
            .document(uid)
            .collection("savedRecipes")
            .document(recipeId)

        savedRecipeIds.remove(recipeId)

        docRef.delete { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.savedRecipeIds.insert(recipeId)
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func fetchSavedRecipes(recipeIdsInOrder: [String]) {
        guard !recipeIdsInOrder.isEmpty else {
            savedRecipes = []
            return
        }

        let orderMap = Dictionary(uniqueKeysWithValues: recipeIdsInOrder.enumerated().map { ($0.element, $0.offset) })
        let chunks = recipeIdsInOrder.chunked(into: 10)
        var allRecipes: [CookLoop.Recipe] = []
        let group = DispatchGroup()

        for chunk in chunks where !chunk.isEmpty {
            group.enter()
            db.collection("recipes")
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments { snapshot, error in
                    defer { group.leave() }

                    if let error = error {
                        DispatchQueue.main.async {
                            self.errorMessage = error.localizedDescription
                        }
                        return
                    }

                    let mapped = snapshot?.documents.compactMap { doc in
                        RecipeViewModel.parseRecipe(id: doc.documentID, data: doc.data())
                    } ?? []

                    allRecipes.append(contentsOf: mapped)
                }
        }

        group.notify(queue: .main) {
            self.savedRecipes = allRecipes.sorted {
                (orderMap[$0.id] ?? Int.max) < (orderMap[$1.id] ?? Int.max)
            }
        }
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [] }
        var chunks: [[Element]] = []
        var index = 0

        while index < count {
            let end = Swift.min(index + size, count)
            chunks.append(Array(self[index..<end]))
            index += size
        }

        return chunks
    }
}
