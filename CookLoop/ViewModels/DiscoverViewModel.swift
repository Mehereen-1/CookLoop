//
//  DiscoverViewModel.swift
//  CookLoop
//
//  Created by GitHub Copilot on 8/4/26.
//

import Foundation

final class DiscoverViewModel: ObservableObject {
    @Published var recipes: [APIRecipe] = []
    @Published var isLoading = false
    @Published var errorMessage = ""

    func fetchRecipes(searchTerm: String = "") {
        var components = URLComponents(string: "https://www.themealdb.com/api/json/v1/1/search.php")
        components?.queryItems = [URLQueryItem(name: "s", value: searchTerm)]

        guard let url = components?.url else {
            DispatchQueue.main.async {
                self.errorMessage = "Invalid API URL.."
            }
            return
        }

        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = ""
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    self.recipes = []
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "No data returned from API."
                    self.recipes = []
                }
                return
            }

            do {
                let decoded = try JSONDecoder().decode(APIResponse.self, from: data)
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.recipes = decoded.meals
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Failed to parse recipes."
                    self.recipes = []
                }
            }
        }.resume()
    }
}
