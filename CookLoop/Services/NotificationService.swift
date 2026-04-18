//
//  NotificationService.swift
//  CookLoop
//
//  Created by GitHub Copilot on 14/4/26.
//

import Foundation
import FirebaseFirestore

final class NotificationService {
    static let shared = NotificationService()

    private let db = Firestore.firestore()

    private init() {}

    func send(
        to recipientUserId: String,
        actorUserId: String,
        actorName: String,
        type: ActivityType,
        recipeId: String? = nil,
        text: String? = nil
    ) {
        guard !recipientUserId.isEmpty, !actorUserId.isEmpty, recipientUserId != actorUserId else { return }

        var payload: [String: Any] = [
            "actorUserId": actorUserId,
            "actorName": actorName,
            "recipientUserId": recipientUserId,
            "type": type.rawValue,
            "createdAt": Timestamp(date: Date())
        ]

        if let recipeId = recipeId, !recipeId.isEmpty {
            payload["recipeId"] = recipeId
        }

        if let text = text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
            payload["text"] = text
        }

        db.collection("users")
            .document(recipientUserId)
            .collection("notifications")
            .document()
            .setData(payload)
    }
}
