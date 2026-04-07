//
//  FirebaseManager.swift
//  CookLoop
//
//  Created by Ayesha Meherin on 27/3/26.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore

class FirebaseManager {
    static let shared = FirebaseManager()

    let auth: Auth
    let firestore: Firestore

    private init() {
        FirebaseApp.configure()
        self.auth = Auth.auth()
        self.firestore = Firestore.firestore()
    }
}
