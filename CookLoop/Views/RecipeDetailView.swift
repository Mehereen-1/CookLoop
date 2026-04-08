//
//  RecipeDetailView.swift
//  CookLoop
//
//  Created by GitHub Copilot on 7/4/26.
//

import SwiftUI

struct RecipeDetailView: View {
    @StateObject private var viewModel: RecipeDetailViewModel
    @StateObject private var commentsViewModel = CommentsViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var bookmarkViewModel: BookmarkViewModel
    @State private var commentText: String = ""

    init(recipe: Recipe) {
        _viewModel = StateObject(wrappedValue: RecipeDetailViewModel(recipe: recipe))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    imageSection

                    NavigationLink(destination: ProfileView(userId: viewModel.recipe.userId)) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.crop.circle.fill")
                                .foregroundColor(.orange)
                            Text(viewModel.creatorName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())

                    Text(viewModel.recipe.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    likeRow

                    if !viewModel.recipe.ingredients.isEmpty {
                        Text("Ingredients")
                            .font(.headline)

                        ForEach(Array(viewModel.recipe.ingredients.enumerated()), id: \.offset) { _, ingredient in
                            Text("• \(ingredient)")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }

                    if !viewModel.recipe.steps.isEmpty {
                        Text("Steps")
                            .font(.headline)
                            .padding(.top, 4)

                        ForEach(Array(viewModel.recipe.steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(index + 1).")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.orange)
                                Text(step)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    commentsSection

                    if !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .foregroundColor(.red)
                    }

                    if !commentsViewModel.errorMessage.isEmpty {
                        Text(commentsViewModel.errorMessage)
                            .foregroundColor(.red)
                    }
                }
                .padding()
            }

            commentInputBar
        }
        .navigationTitle("Recipe")
        .onAppear {
            viewModel.load()
            commentsViewModel.observeComments(recipeId: viewModel.recipe.id)
        }
        .onDisappear {
            commentsViewModel.stopListening()
        }
    }

    private var imageSection: some View {
        Group {
            if !viewModel.recipe.imageUrl.isEmpty {
                RemoteImageView(urlString: viewModel.recipe.imageUrl)
            } else if let imageData = viewModel.recipe.legacyImageData,
                      let data = Data(base64Encoded: imageData),
                      let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color.orange.opacity(0.12))
                    .overlay(
                        Image(systemName: "fork.knife.circle")
                            .font(.system(size: 42))
                            .foregroundColor(Color.orange.opacity(0.6))
                    )
            }
        }
        .frame(height: 240)
        .clipped()
        .cornerRadius(16)
    }

    private var likeRow: some View {
        HStack(spacing: 10) {
            Button(action: {
                viewModel.toggleLike()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.isLiked ? "heart.fill" : "heart")
                        .foregroundColor(viewModel.isLiked ? .red : .gray)
                    Text(viewModel.isLiked ? "Liked" : "Like")
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
            }

            Text("\(viewModel.recipe.likes) likes")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Button(action: {
                bookmarkViewModel.toggleSaved(recipe: viewModel.recipe)
            }) {
                Image(systemName: bookmarkViewModel.isSaved(recipeId: viewModel.recipe.id) ? "bookmark.fill" : "bookmark")
                    .foregroundColor(bookmarkViewModel.isSaved(recipeId: viewModel.recipe.id) ? .orange : .gray)
            }
        }
    }

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Comments")
                .font(.headline)

            if commentsViewModel.comments.isEmpty {
                Text("Be the first to comment.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 0) {
                    ForEach(commentsViewModel.comments) { comment in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(comment.username)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Text(commentTimeString(comment.createdAt))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Text(comment.text)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)

                        if comment.id != commentsViewModel.comments.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(10)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }

    private var commentInputBar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 10) {
                TextField("Add a comment...", text: $commentText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button(action: submitComment) {
                    if commentsViewModel.isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .frame(width: 22, height: 22)
                    } else {
                        Text("Send")
                            .fontWeight(.semibold)
                    }
                }
                .disabled(commentsViewModel.isSubmitting)
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 12)
            .background(Color(UIColor.systemBackground))
        }
    }

    private func submitComment() {
        let trimmed = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        commentsViewModel.addComment(
            recipeId: viewModel.recipe.id,
            text: trimmed,
            currentUser: authViewModel.currentUser
        )
        commentText = ""
    }

    private func commentTimeString(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct RecipeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleRecipe = Recipe(
            id: "preview-recipe",
            userId: "preview-user",
            title: "Creamy Tomato Pasta",
            imageUrl: "",
            legacyImageData: nil,
            ingredients: ["Pasta", "Tomato", "Cream"],
            steps: ["Boil pasta", "Prepare sauce", "Mix and serve"],
            likes: 12,
            createdAt: Date()
        )

        NavigationView {
            RecipeDetailView(recipe: sampleRecipe)
        }
    }
}