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
    @Published var recipes: [Recipe] = []
    @Published var isFollowing: Bool = false

    private let db = Firestore.firestore()

    func fetchUser(userId: String) {
        db.collection("users").document(userId).getDocument { snapshot, error in
            guard let data = snapshot?.data() else { return }

            do {
                let user = User(
                    id: data["id"] as? String ?? "",
                    name: data["name"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    profileImage: data["profileImage"] as? String,
                    bio: data["bio"] as? String
                )
                DispatchQueue.main.async {
                    self.user = user
                }
            }
        }
    }

    func fetchUserRecipes(userId: String) {
        db.collection("recipes")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in

                guard let documents = snapshot?.documents else { return }

                let recipes = documents.compactMap { doc -> Recipe? in
                    let data = doc.data()
                    let createdAtTimestamp = data["createdAt"] as? Timestamp
                    let legacyTimestamp = data["timestamp"] as? Timestamp

                    return Recipe(
                        id: doc.documentID,
                        userId: data["userId"] as? String ?? "",
                        title: data["title"] as? String ?? "",
                        imageUrl: data["imageUrl"] as? String ?? "",
                        legacyImageData: data["imageData"] as? String,
                        ingredients: data["ingredients"] as? [String] ?? [],
                        steps: data["steps"] as? [String] ?? [],
                        likes: data["likes"] as? Int ?? 0,
                        createdAt: createdAtTimestamp?.dateValue() ?? legacyTimestamp?.dateValue() ?? Date()
                    )
                }

                DispatchQueue.main.async {
                    self.recipes = recipes
                }
            }
    }
    
    func updateProfile(name: String, bio: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(uid).updateData([
            "name": name,
            "bio": bio
        ]) { error in
            if let error = error {
                print("Error updating profile:", error.localizedDescription)
            } else {
                DispatchQueue.main.async {
                    self.user?.name = name
                    self.user?.bio = bio
                }
            }
        }
    }

    // MARK: - Follow / Unfollow
    func toggleFollow(targetUserId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        let ref = db.collection("followers")
            .document(targetUserId)
            .collection("userFollowers")
            .document(currentUserId)

        if isFollowing {
            ref.delete()
            isFollowing = false
        } else {
            ref.setData([:])
            isFollowing = true
        }
    }

    func checkIfFollowing(targetUserId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        db.collection("followers")
            .document(targetUserId)
            .collection("userFollowers")
            .document(currentUserId)
            .getDocument { snapshot, _ in

                DispatchQueue.main.async {
                    self.isFollowing = snapshot?.exists ?? false
                }
            }
    }
}
