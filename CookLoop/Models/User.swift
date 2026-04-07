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
}
