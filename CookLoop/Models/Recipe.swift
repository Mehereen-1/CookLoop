//
//  Recipe.swift
//  CookLoop
//
//  Created by Ayesha Meherin on 27/3/26.
//

import Foundation

struct Recipe: Identifiable, Codable {
    var id: String
    var userId: String
    var title: String
    var imageUrl: String
    var legacyImageData: String?
    var ingredients: [String]
    var steps: [String]
    var likes: Int
    var createdAt: Date
    var cookingTimeMinutes: Int = 30
    var difficulty: String = "Intermediate"
    var tags: [String] = []
}
