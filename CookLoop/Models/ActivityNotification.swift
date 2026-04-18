//
//  ActivityNotification.swift
//  CookLoop
//
//  Created by GitHub Copilot on 14/4/26.
//

import Foundation
import FirebaseFirestore

enum ActivityType: String, CaseIterable {
    case like
    case comment
    case follow
    case repost

    var title: String {
        switch self {
        case .like:
            return "liked your recipe"
        case .comment:
            return "commented on your recipe"
        case .follow:
            return "started following you"
        case .repost:
            return "reposted your recipe"
        }
    }

    var iconName: String {
        switch self {
        case .like:
            return "heart.fill"
        case .comment:
            return "message.fill"
        case .follow:
            return "person.badge.plus"
        case .repost:
            return "arrow.2.squarepath"
        }
    }
}

struct ActivityNotification: Identifiable {
    let id: String
    let actorUserId: String
    let actorName: String
    let recipientUserId: String
    let type: ActivityType
    let recipeId: String?
    let text: String?
    let createdAt: Date

    static func fromDocument(id: String, data: [String: Any]) -> ActivityNotification? {
        guard let actorUserId = data["actorUserId"] as? String,
              let recipientUserId = data["recipientUserId"] as? String,
              let typeRaw = data["type"] as? String,
              let type = ActivityType(rawValue: typeRaw) else {
            return nil
        }

        let actorName = data["actorName"] as? String ?? "Someone"
        let recipeId = data["recipeId"] as? String
        let text = data["text"] as? String
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()

        return ActivityNotification(
            id: id,
            actorUserId: actorUserId,
            actorName: actorName,
            recipientUserId: recipientUserId,
            type: type,
            recipeId: recipeId,
            text: text,
            createdAt: createdAt
        )
    }
}
