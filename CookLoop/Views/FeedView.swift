//
//  FeedView.swift
//  CookLoop
//
//  Created by Ayesha Meherin on 26/3/26.
//

import SwiftUI

struct Recipe: Identifiable {
    let id = UUID()
    let title: String
    let image: String
    var isLiked: Bool = false
}

struct FeedView: View {
    @State private var recipes = [
        Recipe(title: "Creamy Pasta", image: "food1"),
        Recipe(title: "Chocolate Cake", image: "food2"),
        Recipe(title: "Healthy Salad", image: "food3")
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(recipes.indices, id: \.self) { index in
                        RecipeCard(recipe: $recipes[index])
                    }
                }
                .padding()
            }
            .navigationTitle("CookLoop")
        }
    }
}

struct RecipeCard: View {
    @Binding var recipe: Recipe

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image(recipe.image)
                .resizable()
                .scaledToFill()
                .frame(height: 250)
                .clipped()
                .cornerRadius(20)

            LinearGradient(
                gradient: Gradient(colors: [.clear, .black.opacity(0.6)]),
                startPoint: .center,
                endPoint: .bottom
            )
            .cornerRadius(20)

            VStack(alignment: .leading) {
                Text(recipe.title)
                    .font(.headline)
                    .foregroundColor(.white)

                HStack {
                    Button(action: {
                        recipe.isLiked.toggle()
                    }) {
                        Image(systemName: recipe.isLiked ? "heart.fill" : "heart")
                            .foregroundColor(.white)
                    }

                    Button(action: {}) {
                        Image(systemName: "bookmark")
                            .foregroundColor(.white)
                    }
                }
            }
            .padding()
        }
    }
}

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
}
