//
//  AuthViewModel.swift
//  CookLoop
//
//  Created by Ayesha Meherin on 27/3/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false

    private let manager = FirebaseManager.shared

    init() {
        self.userSession = manager.auth.currentUser
    }

    // MARK: - Login
    func login(email: String, password: String) {
        isLoading = true

        manager.auth.signIn(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                self.isLoading = false

                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                self.userSession = result?.user
                self.fetchUser()
            }
        }
    }

    // MARK: - Signup
    func signup(name: String, email: String, password: String) {
        isLoading = true

        manager.auth.createUser(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                self.isLoading = false

                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                guard let user = result?.user else { return }

                let newUser = User(
                    id: user.uid,
                    name: name,
                    email: email,
                    profileImage: nil,
                    bio: ""
                )

                do {
                    self.manager.firestore.collection("users")
                        .document(user.uid)
                        .setData([
                            "id": newUser.id,
                            "name": newUser.name,
                            "email": newUser.email,
                            "profileImage": newUser.profileImage ?? "",
                            "bio": newUser.bio ?? ""
                        ])
                    self.userSession = user
                    self.currentUser = newUser
                }
            }
        }
    }

    // MARK: - Fetch User
    func fetchUser() {
        guard let uid = manager.auth.currentUser?.uid else { return }

        manager.firestore.collection("users").document(uid).getDocument { snapshot, error in
            if let data = snapshot?.data() {
                do {
                    let user = User(
                        id: data["id"] as? String ?? "",
                        name: data["name"] as? String ?? "",
                        email: data["email"] as? String ?? "",
                        profileImage: data["profileImage"] as? String,
                        bio: data["bio"] as? String
                    )
                    DispatchQueue.main.async {
                        self.currentUser = user
                    }
                } 
            }
        }
    }

    // MARK: - Logout
    func signOut() {
        try? manager.auth.signOut()
        self.userSession = nil
        self.currentUser = nil
    }
}
