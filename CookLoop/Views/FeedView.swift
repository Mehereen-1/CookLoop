//
//  FeedView.swift
//  CookLoop
//
//  Created by GitHub Copilot on 7/4/26.
//

import SwiftUI
import FirebaseFirestore

struct FeedView: View {
    @StateObject private var viewModel = RecipeViewModel()
    @EnvironmentObject var bookmarkViewModel: BookmarkViewModel
    @State private var userNamesById: [String: String] = [:]
    @State private var selectedRecipe: Recipe?
    @State private var showRecipeDetail = false
    @State private var selectedUserId: String = ""
    @State private var showUserProfile = false

    private let db = Firestore.firestore()
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(viewModel.recipes) { recipe in
                            RecipeCardView(
                                recipe: recipe,
                                username: userNamesById[recipe.userId] ?? "Cook",
                                isLiked: viewModel.likesByRecipeId[recipe.id] ?? false,
                                onLike: { viewModel.toggleLike(for: recipe) },
                                isBookmarked: bookmarkViewModel.isSaved(recipeId: recipe.id),
                                onBookmarkTap: { bookmarkViewModel.toggleSaved(recipe: recipe) },
                                onUserTap: {
                                    selectedUserId = recipe.userId
                                    showUserProfile = true
                                },
                                onCardTap: {
                                    selectedRecipe = recipe
                                    showRecipeDetail = true
                                }
                            )
                            .onAppear {
                                fetchUserNameIfNeeded(for: recipe.userId)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)

                    if !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .foregroundColor(.red)
                            .padding(.top, 8)
                    }
                }

                NavigationLink(
                    destination: recipeDetailDestination,
                    isActive: $showRecipeDetail
                ) {
                    EmptyView()
                }
                .hidden()

                NavigationLink(
                    destination: ProfileView(userId: selectedUserId),
                    isActive: $showUserProfile
                ) {
                    EmptyView()
                }
                .hidden()
            }
            .navigationTitle("CookLoop")
        }
        .onAppear {
            viewModel.fetchRecipes()
            bookmarkViewModel.startListening()
        }
    }

    private func fetchUserNameIfNeeded(for userId: String) {
        if userNamesById[userId] != nil { return }

        db.collection("users").document(userId).getDocument { snapshot, _ in
            guard let data = snapshot?.data() else { return }

            DispatchQueue.main.async {
                userNamesById[userId] = data["name"] as? String ?? "Cook"
            }
        }
    }

    private var recipeDetailDestination: some View {
        Group {
            if let selectedRecipe = selectedRecipe {
                RecipeDetailView(recipe: selectedRecipe)
            } else {
                Text("Recipe unavailable")
            }
        }
    }
}

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
}