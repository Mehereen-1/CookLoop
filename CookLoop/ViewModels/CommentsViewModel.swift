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
    private var commentsListener: ListenerRegistration?
    private var repliesListenersByCommentId: [String: ListenerRegistration] = [:]
    private var latestTopLevelComments: [Comment] = []
    private var repliesByCommentId: [String: [CommentReply]] = [:]

    deinit {
        stopListening()
    }

    func observeComments(recipeId: String) {
        stopListening()
        errorMessage = ""

        commentsListener = db.collection("recipes")
            .document(recipeId)
            .collection("comments")
            .order(by: "createdAt", descending: true)
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
                            createdAt: createdAt,
                            replies: self.repliesByCommentId[doc.documentID] ?? []
                        )
                    } ?? []

                    self.latestTopLevelComments = mapped
                    self.syncReplyListeners(recipeId: recipeId, comments: mapped)
                    self.rebuildThreadedComments()
                }
            }
    }

    func stopListening() {
        commentsListener?.remove()
        commentsListener = nil

        for listener in repliesListenersByCommentId.values {
            listener.remove()
        }
        repliesListenersByCommentId.removeAll()
        repliesByCommentId.removeAll()
        latestTopLevelComments = []
        comments = []
    }

    func addComment(recipeId: String, text: String, currentUser: User?, completion: ((Bool) -> Void)? = nil) {
        guard !isSubmitting else { return }

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "Please log in to comment.."
            completion?(false)
            return
        }

        isSubmitting = true
        errorMessage = ""

        let fallbackName = (currentUser?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")

        if fallbackName.isEmpty {
            fetchUserName(userId: uid) { fetchedName in
                self.saveComment(recipeId: recipeId, uid: uid, username: fetchedName, text: trimmedText, completion: completion)
            }
        } else {
            saveComment(recipeId: recipeId, uid: uid, username: fallbackName, text: trimmedText, completion: completion)
        }
    }

    func addReply(recipeId: String, parentCommentId: String, text: String, currentUser: User?, completion: ((Bool) -> Void)? = nil) {
        guard !isSubmitting else { return }

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "Please log in to reply."
            completion?(false)
            return
        }

        isSubmitting = true
        errorMessage = ""

        let fallbackName = (currentUser?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")

        if fallbackName.isEmpty {
            fetchUserName(userId: uid) { fetchedName in
                self.saveReply(
                    recipeId: recipeId,
                    parentCommentId: parentCommentId,
                    uid: uid,
                    username: fetchedName,
                    text: trimmedText,
                    completion: completion
                )
            }
        } else {
            saveReply(
                recipeId: recipeId,
                parentCommentId: parentCommentId,
                uid: uid,
                username: fallbackName,
                text: trimmedText,
                completion: completion
            )
        }
    }

    private func fetchUserName(userId: String, completion: @escaping (String) -> Void) {
        db.collection("users").document(userId).getDocument { snapshot, _ in
            let fetched = snapshot?.data()? ["name"] as? String
            let normalized = fetched?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            completion(normalized.isEmpty ? "Cook" : normalized)
        }
    }

    private func saveComment(recipeId: String, uid: String, username: String, text: String, completion: ((Bool) -> Void)? = nil) {
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
                    completion?(false)
                    return
                }

                GamificationService.shared.awardComment(userId: uid)
                self.sendCommentNotification(recipeId: recipeId, actorUserId: uid, actorName: username, text: text)
                completion?(true)
            }
        }
    }

    private func saveReply(recipeId: String, parentCommentId: String, uid: String, username: String, text: String, completion: ((Bool) -> Void)? = nil) {
        let replyRef = db.collection("recipes")
            .document(recipeId)
            .collection("comments")
            .document(parentCommentId)
            .collection("replies")
            .document()

        let payload: [String: Any] = [
            "id": replyRef.documentID,
            "userId": uid,
            "username": username,
            "text": text,
            "createdAt": Timestamp(date: Date()),
            "parentCommentId": parentCommentId
        ]

        replyRef.setData(payload) { error in
            DispatchQueue.main.async {
                self.isSubmitting = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    completion?(false)
                    return
                }

                GamificationService.shared.awardComment(userId: uid)
                self.sendCommentNotification(recipeId: recipeId, actorUserId: uid, actorName: username, text: text)
                completion?(true)
            }
        }
    }

    private func sendCommentNotification(recipeId: String, actorUserId: String, actorName: String, text: String) {
        db.collection("recipes").document(recipeId).getDocument { snapshot, _ in
            let ownerId = snapshot?.data()?["userId"] as? String ?? ""

            NotificationService.shared.send(
                to: ownerId,
                actorUserId: actorUserId,
                actorName: actorName,
                type: .comment,
                recipeId: recipeId,
                text: text
            )
        }
    }

    private func syncReplyListeners(recipeId: String, comments: [Comment]) {
        let commentIDs = Set(comments.map { $0.id })

        for (commentId, listener) in repliesListenersByCommentId where !commentIDs.contains(commentId) {
            listener.remove()
            repliesListenersByCommentId.removeValue(forKey: commentId)
            repliesByCommentId.removeValue(forKey: commentId)
        }

        for comment in comments where repliesListenersByCommentId[comment.id] == nil {
            let listener = db.collection("recipes")
                .document(recipeId)
                .collection("comments")
                .document(comment.id)
                .collection("replies")
                .order(by: "createdAt", descending: false)
                .addSnapshotListener { snapshot, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self.errorMessage = error.localizedDescription
                            return
                        }

                        let mappedReplies: [CommentReply] = snapshot?.documents.compactMap { doc in
                            let data = doc.data()
                            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()

                            return CommentReply(
                                id: doc.documentID,
                                userId: data["userId"] as? String ?? "",
                                username: data["username"] as? String ?? "Cook",
                                text: data["text"] as? String ?? "",
                                createdAt: createdAt,
                                parentCommentId: data["parentCommentId"] as? String ?? comment.id
                            )
                        } ?? []

                        self.repliesByCommentId[comment.id] = mappedReplies
                        self.rebuildThreadedComments()
                    }
                }

            repliesListenersByCommentId[comment.id] = listener
        }
    }

    private func rebuildThreadedComments() {
        comments = latestTopLevelComments.map { comment in
            var updatedComment = comment
            updatedComment.replies = repliesByCommentId[comment.id] ?? []
            return updatedComment
        }
    }
}