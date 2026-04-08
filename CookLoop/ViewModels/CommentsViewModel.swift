//
//  CommentsViewModel.swift
//  CookLoop
//
//  Created by GitHub Copilot on 7/4/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class CommentsViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var isSubmitting = false
    @Published var errorMessage = ""

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    deinit {
        stopListening()
    }

    func observeComments(recipeId: String) {
        stopListening()

        listener = db.collection("recipes")
            .document(recipeId)
            .collection("comments")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        return
                    }

                    let mapped: [Comment] = snapshot?.documents.compactMap { doc in
                        let data = doc.data()
                        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()

                        return Comment(
                            id: doc.documentID,
                            userId: data["userId"] as? String ?? "",
                            username: data["username"] as? String ?? "Cook",
                            text: data["text"] as? String ?? "",
                            createdAt: createdAt
                        )
                    } ?? []

                    self.comments = mapped
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func addComment(recipeId: String, text: String, currentUser: User?) {
        guard !isSubmitting else { return }

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }

        isSubmitting = true
        errorMessage = ""

        let fallbackName = (currentUser?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")

        if fallbackName.isEmpty {
            fetchUserName(userId: uid) { fetchedName in
                self.saveComment(recipeId: recipeId, uid: uid, username: fetchedName, text: trimmedText)
            }
        } else {
            saveComment(recipeId: recipeId, uid: uid, username: fallbackName, text: trimmedText)
        }
    }

    private func fetchUserName(userId: String, completion: @escaping (String) -> Void) {
        db.collection("users").document(userId).getDocument { snapshot, _ in
            let fetched = snapshot?.data()? ["name"] as? String
            let normalized = fetched?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            completion(normalized.isEmpty ? "Cook" : normalized)
        }
    }

    private func saveComment(recipeId: String, uid: String, username: String, text: String) {
        let commentRef = db.collection("recipes")
            .document(recipeId)
            .collection("comments")
            .document()

        let payload: [String: Any] = [
            "id": commentRef.documentID,
            "userId": uid,
            "username": username,
            "text": text,
            "createdAt": Timestamp(date: Date())
        ]

        commentRef.setData(payload) { error in
            DispatchQueue.main.async {
                self.isSubmitting = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}