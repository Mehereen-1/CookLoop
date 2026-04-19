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
        errorMessage = ""

        manager.auth.signIn(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    return
                }

                self.userSession = result?.user
                self.fetchUser { user in
                    DispatchQueue.main.async {
                        self.isLoading = false

                        guard let user = user else {
                            self.errorMessage = "Unable to load account details."
                            return
                        }

                        if user.isBanned {
                            self.errorMessage = "Your account has been banned.. Please contact support."
                            self.forceLogoutForAccessViolation()
                            return
                        }

                        GamificationService.shared.runWeeklyCalculation()
                    }
                }
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
                    bio: "",
                    isAdmin: false,
                    isBanned: false,
                    xp: 0,
                    level: "Beginner Cook",
                    badges: []
                )

                do {
                    self.manager.firestore.collection("users")
                        .document(user.uid)
                        .setData([
                            "id": newUser.id,
                            "name": newUser.name,
                            "email": newUser.email,
                            "profileImage": newUser.profileImage ?? "",
                            "bio": newUser.bio ?? "",
                            "isAdmin": newUser.isAdmin,
                            "isBanned": newUser.isBanned,
                            "xp": newUser.xp,
                            "level": newUser.level,
                            "badges": newUser.badges,
                            "totalRecipesPosted": 0,
                            "totalLikesReceived": 0,
                            "totalComments": 0,
                            "totalBookmarks": 0
                        ])
                    self.userSession = user
                    self.currentUser = newUser
                    GamificationService.shared.runWeeklyCalculation()
                }
            }
        }
    }

    // MARK: - Fetch User
    func fetchUser(completion: ((User?) -> Void)? = nil) {
        guard let uid = manager.auth.currentUser?.uid else { return }

        manager.firestore.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    completion?(nil)
                }
                return
            }

            if let data = snapshot?.data() {
                do {
                    let user = User(
                        id: data["id"] as? String ?? "",
                        name: data["name"] as? String ?? "",
                        email: data["email"] as? String ?? "",
                        profileImage: data["profileImage"] as? String,
                        bio: data["bio"] as? String,
                        isAdmin: data["isAdmin"] as? Bool ?? false,
                        isBanned: data["isBanned"] as? Bool ?? false,
                        xp: Self.parseInt(data["xp"]) ?? 0,
                        level: data["level"] as? String ?? "Beginner Cook",
                        badges: data["badges"] as? [String] ?? []
                    )
                    DispatchQueue.main.async {
                        if user.isBanned {
                            self.errorMessage = "Your account has been banned. Please contact support."
                            self.forceLogoutForAccessViolation()
                            completion?(nil)
                            return
                        }

                        self.currentUser = user
                        completion?(user)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion?(nil)
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

    private func forceLogoutForAccessViolation() {
        try? manager.auth.signOut()
        self.userSession = nil
        self.currentUser = nil
    }
}
