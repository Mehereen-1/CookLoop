//
//  APIDetailView.swift
//  CookLoop
//
//  Created by GitHub Copilot on 8/4/26.
//

import SwiftUI

struct APIDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    let recipe: APIRecipe

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    AppTopBar(
                        subtitle: "Recipe details",
                        showsBackButton: true,
                        trailingSystemIcon: nil,
                        onBackTap: { presentationMode.wrappedValue.dismiss() }
                    )

                    if !recipe.strMealThumb.isEmpty {
                        RemoteImageView(urlString: recipe.strMealThumb)
                            .frame(height: 250)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                    } else {
                        Rectangle()
                            .fill(Color.secondaryContainer.opacity(0.4))
                            .overlay(
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 42))
                                    .foregroundColor(.onSecondaryContainer)
                            )
                            .frame(height: 250)
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                    }

                    Text(recipe.strMeal)
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundColor(.onSurface)

                    if recipe.strCategory != nil || recipe.strArea != nil {
                        HStack(spacing: 8) {
                            if let category = recipe.strCategory, !category.isEmpty {
                                infoBadge(text: category)
                            }
                            if let area = recipe.strArea, !area.isEmpty {
                                infoBadge(text: area)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Instructions")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.onSurface)

                        Text(recipe.strInstructions)
                            .font(.body)
                            .foregroundColor(.onSurfaceVariant)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .background(Color.surfaceContainerLowest)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .padding(20)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }

    private func infoBadge(text: String) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.onSecondaryContainer)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.secondaryContainer)
            .clipShape(Capsule())
    }
}

struct APIDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let recipe = APIRecipe(
            idMeal: "1",
            strMeal: "Sample Teriyaki Chicken",
            strMealThumb: "",
            strInstructions: "Mix, cook, and serve.",
            strCategory: "Chicken",
            strArea: "Japanese"
        )

        NavigationView {
            APIDetailView(recipe: recipe)
        }
    }
}
