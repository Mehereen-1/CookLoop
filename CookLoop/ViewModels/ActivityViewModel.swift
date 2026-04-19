//
//  ActivityViewModel.swift
//  CookLoop
//
//  Created by GitHub Copilot on 14/4/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class ActivityViewModel: ObservableObject {
    @Published var notifications: [ActivityNotification] = []
    @Published var errorMessage: String = " "

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    deinit {
        stopListening()
    }

    func startListening() {
        stopListening()

        guard let uid = Auth.auth().currentUser?.uid else {
            notifications = []
            return
        }

        listener = db.collection("users")
            .document(uid)
            .collection("notifications")
            .order(by: "createdAt", descending: true)
            .limit(to: 100)
            .addSnapshotListener { snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        return
                    }

                    let mapped: [ActivityNotification] = snapshot?.documents.compactMap { doc in
                        ActivityNotification.fromDocument(id: doc.documentID, data: doc.data())
                    } ?? []

                    self.notifications = mapped
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }
}
