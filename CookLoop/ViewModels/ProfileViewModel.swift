//
//  ProfileViewModel.swift
//  CookLoop
//
//  Created by Ayesha Meherin on 27/3/26.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var recipes: [CookLoop.Recipe] = []
    @Published var isFollowing: Bool = false
    @Published var followersCount: Int = 0
    @Published var followingCount: Int = 0

    private let db = Firestore.firestore()

    func fetchUser(userId: String) {
        db.collection("users").document(userId).getDocument { snapshot, error in
            guard let data = snapshot?.data() else { return }

            let resolvedId = (data["id"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let fallbackId = snapshot?.documentID ?? userId

            do {
                let user = User(
                    id: (resolvedId?.isEmpty == false ? resolvedId! : fallbackId),
                    name: data["name"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    profileImage: data["profileImage"] as? String,
                    bio: data["bio"] as? String,
                    xp: Self.parseInt(data["xp"]) ?? 0,
                    level: data["level"] as? String ?? "Beginner Cook",
                    badges: data["badges"] as? [String] ?? []
                )
                DispatchQueue.main.async {
                    self.user = user
                }
            }
        }
    }

    func fetchUserRecipes(userId: String) {
        let trimmedInputId = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        let authUid = Auth.auth().currentUser?.uid.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let targetUserId = trimmedInputId.isEmpty ? authUid : trimmedInputId

        guard !targetUserId.isEmpty else {
            DispatchQueue.main.async {
                self.recipes = []
            }
            return
        }

        db.collection("recipes")
            .whereField("userId", isEqualTo: targetUserId)
            .getDocuments { snapshot, _ in
                let fetched = snapshot?.documents.compactMap { doc -> CookLoop.Recipe? in
                    RecipeViewModel.parseRecipe(id: doc.documentID, data: doc.data())
                } ?? []

                DispatchQueue.main.async {
                    self.recipes = fetched.sorted { $0.createdAt > $1.createdAt }
                }
            }
    }
    
    func updateProfile(
        name: String,
        bio: String,
        profileImage: String? = nil,
        completion: ((Bool, String?) -> Void)? = nil
    ) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        var payload: [String: Any] = [
            "name": name,
            "bio": bio
        ]

        if let profileImage = profileImage {
            payload["profileImage"] = profileImage
        }

        db.collection("users").document(uid).updateData(payload) { error in
            if let error = error {
                print("Error updating profile:", error.localizedDescription)
                DispatchQueue.main.async {
                    completion?(false, error.localizedDescription)
                }
            } else {
                DispatchQueue.main.async {
                    self.user?.name = name
                    self.user?.bio = bio
                    if let profileImage = profileImage {
                        self.user?.profileImage = profileImage
                    }
                    completion?(true, nil)
                }
            }
        }
    }

    func changePassword(
        currentPassword: String,
        newPassword: String,
        completion: @escaping (Bool, String?) -> Void
    ) {
        guard let authUser = Auth.auth().currentUser,
              let email = authUser.email else {
            completion(false, "Unable to find your account session. Please log in again.")
            return
        }

        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)

        authUser.reauthenticate(with: credential) { _, reauthError in
            if let reauthError = reauthError {
                DispatchQueue.main.async {
                    completion(false, reauthError.localizedDescription)
                }
                return
            }

            authUser.updatePassword(to: newPassword) { updateError in
                DispatchQueue.main.async {
                    if let updateError = updateError {
                        completion(false, updateError.localizedDescription)
                    } else {
                        completion(true, nil)
                    }
                }
            }
        }
    }

    func updateRecipe(
        recipeId: String,
        title: String,
        imageUrl: String,
        ingredients: [String],
        steps: [String],
        cookingTimeMinutes: Int,
        difficulty: String,
        tags: [String],
        completion: ((Bool) -> Void)? = nil
    ) {
        let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedTitle.isEmpty else {
            completion?(false)
            return
        }

        let payload: [String: Any] = [
            "title": cleanedTitle,
            "imageUrl": imageUrl.trimmingCharacters(in: .whitespacesAndNewlines),
            "ingredients": ingredients,
            "steps": steps,
            "cookingTimeMinutes": max(5, cookingTimeMinutes),
            "difficulty": difficulty.trimmingCharacters(in: .whitespacesAndNewlines),
            "tags": tags
        ]

        db.collection("recipes").document(recipeId).updateData(payload) { error in
            DispatchQueue.main.async {
                completion?(error == nil)
            }
        }
    }

    func deleteRecipe(recipeId: String, completion: ((Bool) -> Void)? = nil) {
        db.collection("recipes").document(recipeId).delete { error in
            DispatchQueue.main.async {
                if error == nil {
                    self.recipes.removeAll { $0.id == recipeId }
                    completion?(true)
                } else {
                    completion?(false)
                }
            }
        }
    }

    // MARK: - Follow / Unfollow
    func toggleFollow(targetUserId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        guard currentUserId != targetUserId else { return }

        let followingRef = db.collection("users")
            .document(currentUserId)
            .collection("following")
            .document(targetUserId)

        let followerRef = db.collection("users")
            .document(targetUserId)
            .collection("followers")
            .document(currentUserId)

        let batch = db.batch()

        if isFollowing {
            batch.deleteDocument(followingRef)
            batch.deleteDocument(followerRef)
        } else {
            let payload: [String: Any] = [
                "userId": targetUserId,
                "createdAt": Timestamp(date: Date())
            ]
            let reversePayload: [String: Any] = [
                "userId": currentUserId,
                "createdAt": Timestamp(date: Date())
            ]

            batch.setData(payload, forDocument: followingRef)
            batch.setData(reversePayload, forDocument: followerRef)
        }

        batch.commit { error in
            DispatchQueue.main.async {
                if error != nil { return }

                self.isFollowing.toggle()
                if self.isFollowing {
                    self.followersCount += 1
                    self.notifyFollowTarget(targetUserId: targetUserId)
                } else {
                    self.followersCount = max(0, self.followersCount - 1)
                }
            }
        }
    }

    func checkIfFollowing(targetUserId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        guard currentUserId != targetUserId else {
            DispatchQueue.main.async {
                self.isFollowing = false
            }
            return
        }

        db.collection("users")
            .document(currentUserId)
            .collection("following")
            .document(targetUserId)
            .getDocument { snapshot, _ in

                DispatchQueue.main.async {
                    self.isFollowing = snapshot?.exists ?? false
                }
            }
    }

    func fetchFollowStats(userId: String) {
        db.collection("users")
            .document(userId)
            .collection("followers")
            .getDocuments { snapshot, _ in
                DispatchQueue.main.async {
                    self.followersCount = snapshot?.documents.count ?? 0
                }
            }

        db.collection("users")
            .document(userId)
            .collection("following")
            .getDocuments { snapshot, _ in
                DispatchQueue.main.async {
                    self.followingCount = snapshot?.documents.count ?? 0
                }
            }
    }

    private func notifyFollowTarget(targetUserId: String) {
        guard let actorUserId = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(actorUserId).getDocument { snapshot, _ in
            let fetchedName = snapshot?.data()?["name"] as? String
            let actorName = fetchedName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            NotificationService.shared.send(
                to: targetUserId,
                actorUserId: actorUserId,
                actorName: actorName.isEmpty ? "Cook" : actorName,
                type: .follow,
                recipeId: nil,
                text: nil
            )
        }
    }

    private static func parseInt(_ value: Any?) -> Int? {
        if let intValue = value as? Int {
            return intValue
        }

        if let int64Value = value as? Int64 {
            return Int(int64Value)
        }

        if let doubleValue = value as? Double {
            return Int(doubleValue)
        }

        return nil
    }
}
