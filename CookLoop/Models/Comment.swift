//
//  Comment.swift
//  CookLoop
//
//  Created by GitHub Copilot on 7/4/26.
//

import Foundation

struct Comment: Identifiable, Codable {
    var id: String
    var userId: String
    var username: String
    var text: String
    var createdAt: Date
    var replies: [CommentReply] = []
}

struct CommentReply: Identifiable, Codable {
    var id: String
    var userId: String
    var username: String
    var text: String
    var createdAt: Date
    var parentCommentId: String
}