//
//  APIRecipe.swift
//  CookLoop
//
//  Created by GitHub Copilot on 8/4/26.
//

import Foundation

struct APIRecipe: Codable, Identifiable {
    let idMeal: String
    let strMeal: String
    let strMealThumb: String
    let strInstructions: String
    let strCategory: String?
    let strArea: String?

    var id: String { idMeal }
}

struct APIResponse: Codable {
    let meals: [APIRecipe]

    private enum CodingKeys: String, CodingKey {
        case meals
    }

    init(meals: [APIRecipe]) {
        self.meals = meals
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        meals = (try? container.decode([APIRecipe].self, forKey: .meals)) ?? []
    }
}
