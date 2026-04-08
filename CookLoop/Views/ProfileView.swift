//
//  ProfileView.swift
//  CookLoop
//
//  Created by Ayesha Meherin on 26/3/26.
//

import SwiftUI
import FirebaseFirestore

struct ProfileView: View {
    @StateObject var viewModel = ProfileViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var bookmarkViewModel: BookmarkViewModel
    @State private var showEditProfile = false
    @State private var selectedRecipe: Recipe?
    @State private var showRecipeDetail = false
    @State private var selectedUserId: String = ""
    @State private var showUserProfile = false
    @State private var selectedSection: ProfileSection = .myRecipes
    @State private var userNamesById: [String: String] = [:]

    private let db = Firestore.firestore()

    var userId: String

    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var isCurrentUser: Bool {
        authViewModel.currentUser?.id == userId
    }

    private var displayedRecipes: [Recipe] {
        if isCurrentUser && selectedSection == .savedRecipes {
            return bookmarkViewModel.savedRecipes
        }
        return viewModel.recipes
    }

    var body: some View {
        ScrollViewReader { proxy in
            ZStack {
                ScrollView {
                    VStack(spacing: 14) {
                        ProfileHeaderView(
                            name: viewModel.user?.name ?? "Loading...",
                            bio: viewModel.user?.bio ?? ""
                        )

                        if isCurrentUser {
                            HStack(spacing: 10) {
                                Button("Edit Profile") {
                                    showEditProfile = true
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(10)

                                Button("My Recipes") {
                                    selectedSection = .myRecipes
                                    withAnimation {
                                        proxy.scrollTo("my-recipes", anchor: .top)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.orange.opacity(0.85))
                                .foregroundColor(.white)
                                .cornerRadius(10)

                                Button("Logout") {
                                    authViewModel.signOut()
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.gray.opacity(0.25))
                                .foregroundColor(.primary)
                                .cornerRadius(10)
                            }

                            HStack(spacing: 10) {
                                sectionButton(title: "My Recipes", section: .myRecipes)
                                sectionButton(title: "Saved Recipes", section: .savedRecipes)
                            }
                        } else {
                            Button(action: {
                                viewModel.toggleFollow(targetUserId: userId)
                            }) {
                                Text(viewModel.isFollowing ? "Unfollow" : "Follow")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(viewModel.isFollowing ? Color.gray : Color.orange)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(displayedRecipes, id: \.id) { recipe in
                                RecipeCardView(
                                    recipe: recipe,
                                    username: userNamesById[recipe.userId] ?? viewModel.user?.name ?? "Cook",
                                    isLiked: false,
                                    onLike: {},
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
                        .id("my-recipes")

                        if displayedRecipes.isEmpty {
                            Text(selectedSection == .savedRecipes ? "No saved recipes yet." : "No recipes yet.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                    }
                    .padding()
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
        }
        .navigationTitle("Profile")
        .onAppear {
            viewModel.fetchUser(userId: userId)
            viewModel.fetchUserRecipes(userId: userId)

            if isCurrentUser {
                bookmarkViewModel.startListening()
            }

            if !isCurrentUser {
                viewModel.checkIfFollowing(targetUserId: userId)
            }
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView(viewModel: viewModel)
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

    private func sectionButton(title: String, section: ProfileSection) -> some View {
        Button(action: {
            selectedSection = section
        }) {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(selectedSection == section ? Color.orange : Color.gray.opacity(0.2))
                .foregroundColor(selectedSection == section ? .white : .primary)
                .cornerRadius(10)
        }
    }

    private func fetchUserNameIfNeeded(for uid: String) {
        if userNamesById[uid] != nil { return }

        db.collection("users").document(uid).getDocument { snapshot, _ in
            guard let data = snapshot?.data() else { return }

            DispatchQueue.main.async {
                userNamesById[uid] = data["name"] as? String ?? "Cook"
            }
        }
    }
}

private enum ProfileSection {
    case myRecipes
    case savedRecipes
}
