//
//  User.swift
//  CookLoop
//
//  Created by Ayesha Meherin on 27/3/26.
//

import Foundation

struct User: Identifiable, Codable {
    var id: String
    var name: String
    var email: String
    var profileImage: String?
    var bio: String?
    var isAdmin: Bool = false
    var isBanned: Bool = false
    var xp: Int = 0
    var level: String = "Beginner Cook"
    var badges: [String] = []
}
