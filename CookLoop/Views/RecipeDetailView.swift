//
//  RecipeDetailView.swift
//  CookLoop
//
//  Created by GitHub Copilot on 7/4/26.
//

import SwiftUI

struct RecipeDetailView: View {
        @Environment(\.presentationMode) var presentationMode
    @AppStorage(UIChromeStore.hideBottomNavKey) private var hideBottomNav = false
    private let ctaIllustrationURL = "https://lh3.googleusercontent.com/aida-public/AB6AXuAVeFFD9PThuOM9M6NjK4mvnrWN0s_Vx7S7sJQOlNftvS5mXygXxUSbnuHaLnQHlLC2eALTKHCFxAWytIQtAKds1TRHas29aaVTN4M-rNDi5AkF3QlIRWGMPiISwDkoX2Aei8SYwkylds8WPGZEcd-8adGLzNJFcsiN_oh8IfCgcLXSZ3Y4Sw-zLY6RfKT5NscRIbPkijh6w1_GniW1yc_QxfLyuepx1jZKv6M53S9FGgfvK7q5dhUts7BC9l_pQT5eBNYngzz_fU8"

    @StateObject private var viewModel: RecipeDetailViewModel
    @StateObject private var commentsViewModel = CommentsViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var bookmarkViewModel: BookmarkViewModel
    @State private var commentText: String = ""
    @State private var replyingToCommentId: String?
    @State private var replyDraftsByCommentId: [String: String] = [:]

    init(recipe: CookLoop.Recipe) {
        _viewModel = StateObject(wrappedValue: RecipeDetailViewModel(recipe: recipe))
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            decorativeBackgroundSymbols

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        AppTopBar(
                            subtitle: "See ingredients, steps, and more",
                            showsBackButton: true,
                            trailingSystemIcon: nil,
                            onBackTap: { presentationMode.wrappedValue.dismiss() }
                        )

                        heroSection
                        headerCardSection

                        if !viewModel.recipe.ingredients.isEmpty {
                            pantrySection
                        }

                        if !viewModel.recipe.steps.isEmpty {
                            kitchenStorySection
                        }

                        commentsSection
                        startCookingButton

                        if !viewModel.errorMessage.isEmpty {
                            Text(viewModel.errorMessage)
                                .foregroundColor(.red)
                        }

                        if !commentsViewModel.errorMessage.isEmpty {
                            Text(commentsViewModel.errorMessage)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }

                commentInputBar
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            hideBottomNav = true
            viewModel.load()
            commentsViewModel.observeComments(recipeId: viewModel.recipe.id)
        }
        .onDisappear {
            hideBottomNav = false
            commentsViewModel.stopListening()
        }
    }

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            recipeImage
                .frame(height: 360)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 34))

            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.0), Color.black.opacity(0.2)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 34))

            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.onPrimary.opacity(0.9))
                Spacer()
            }
            .padding(16)
        }
    }

    private var recipeImage: some View {
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
                    .fill(Color.secondaryContainer.opacity(0.45))
                    .overlay(
                        Image(systemName: "flame.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.onSecondaryContainer)
                    )
            }
        }
    }

    private var headerCardSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            NavigationLink(destination: ProfileView(userId: viewModel.recipe.userId)) {
                HStack(spacing: 6) {
                    Image(systemName: "person.crop.circle.fill")
                        .foregroundColor(.primaryBrand)
                    Text(viewModel.creatorName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.onSurface)
                }
            }
            .buttonStyle(PlainButtonStyle())

            Text(viewModel.recipe.title)
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundColor(.primaryBrand)
                .lineSpacing(1)

            statsRow
            if !viewModel.recipe.tags.isEmpty {
                recipeTagsRow
            }
            likeRow
        }
        .padding(18)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .stroke(Color.outlineVariant.opacity(0.28), lineWidth: 1)
        )
        .shadow(color: .onSurface.opacity(0.06), radius: 12, x: 0, y: 8)
        .padding(.top, -42)
    }

    private var statsRow: some View {
        HStack(spacing: 14) {
            statChip(icon: "clock", text: "\(displayCookingMinutes) mins")
            statChip(icon: "flame.fill", text: difficultyLabel)
            statChip(icon: "star.fill", text: "\(formattedLikes)")
        }
    }

    private var recipeTagsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.recipe.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.onTertiaryContainer)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.tertiaryContainer.opacity(0.7))
                        .clipShape(Capsule())
                }
            }
        }
    }

    private func statChip(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(.primaryBrand)
            Text(text)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.onSurface)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.surfaceContainerLow)
        .clipShape(Capsule())
    }

    private var pantrySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "basket.fill")
                    .font(.title3)
                    .foregroundColor(.primaryBrand)
                Text("The Pantry List")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(.onSurface)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(Array(viewModel.recipe.ingredients.enumerated()), id: \.offset) { _, ingredient in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color.surfaceContainerLowest)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.caption)
                                    .foregroundColor(.primaryBrand)
                            )

                        Text(ingredient)
                            .font(.subheadline)
                            .foregroundColor(.onSurface)
                            .lineLimit(2)

                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .background(Color.surfaceContainerLow)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }

    private var kitchenStorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "book.fill")
                    .font(.title3)
                    .foregroundColor(.primaryBrand)
                Text("The Kitchen Tale")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(.onSurface)
            }

            VStack(spacing: 12) {
                ForEach(Array(viewModel.recipe.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.primaryBrand)
                            Text("\(index + 1)")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.onPrimary)
                        }
                        .frame(width: 34, height: 34)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(step)
                                .font(.body)
                                .foregroundColor(.onSurface)

                            if index == 2 {
                                Text("Chef's tip: Keep your broth warm so the risotto stays silky while stirring.")
                                    .font(.caption)
                                    .foregroundColor(.onTertiaryContainer)
                                    .padding(10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.tertiaryContainer.opacity(0.6))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(index.isMultiple(of: 2) ? Color.surfaceContainer : Color.surfaceContainerLow)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
        }
    }

    private var likeRow: some View {
        HStack(spacing: 10) {
            Button(action: {
                viewModel.toggleLike()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.isLiked ? "heart.fill" : "heart")
                        .foregroundColor(viewModel.isLiked ? .primaryBrand : .outlineVariant)
                    Text(viewModel.isLiked ? "Liked" : "Like")
                        .fontWeight(.medium)
                        .foregroundColor(.onSurface)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.surfaceContainerLowest)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Text("\(viewModel.recipe.likes) likes")
                .font(.subheadline)
                .foregroundColor(.onSurfaceVariant)

            Spacer()

            Button(action: {
                bookmarkViewModel.toggleSaved(recipe: viewModel.recipe)
            }) {
                Image(systemName: bookmarkViewModel.isSaved(recipeId: viewModel.recipe.id) ? "bookmark.fill" : "bookmark")
                    .foregroundColor(bookmarkViewModel.isSaved(recipeId: viewModel.recipe.id) ? .primaryBrand : .outlineVariant)
            }
        }
    }

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Comments")
                .font(.system(size: 24, weight: .heavy, design: .rounded))

            if commentsViewModel.comments.isEmpty {
                Text("Be the first to comment.")
                    .font(.subheadline)
                    .foregroundColor(.onSurfaceVariant)
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
                                    .foregroundColor(.onSurfaceVariant)
                            }

                            Text(comment.text)
                                .font(.subheadline)
                                .foregroundColor(.onSurface)

                            Button(action: {
                                toggleReplyComposer(for: comment.id)
                            }) {
                                Text(replyingToCommentId == comment.id ? "Cancel" : "Reply")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primaryBrand)
                            }
                            .padding(.top, 4)

                            if replyingToCommentId == comment.id {
                                HStack(spacing: 8) {
                                    TextField(
                                        "Write a reply...",
                                        text: Binding(
                                            get: { replyDraftsByCommentId[comment.id] ?? "" },
                                            set: { replyDraftsByCommentId[comment.id] = $0 }
                                        )
                                    )
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(Color.surfaceContainerLow)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                    Button(action: {
                                        submitReply(for: comment.id)
                                    }) {
                                        Text("Send")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.primaryBrand)
                                    }
                                    .disabled(commentsViewModel.isSubmitting)
                                }
                                .padding(.top, 6)
                            }

                            if !comment.replies.isEmpty {
                                VStack(spacing: 0) {
                                    ForEach(comment.replies) { reply in
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                                Text(reply.username)
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                Text(commentTimeString(reply.createdAt))
                                                    .font(.caption2)
                                                    .foregroundColor(.onSurfaceVariant)
                                            }

                                            Text(reply.text)
                                                .font(.caption)
                                                .foregroundColor(.onSurface)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.leading, 14)
                                        .padding(.vertical, 8)

                                        if reply.id != comment.replies.last?.id {
                                            Divider()
                                        }
                                    }
                                }
                                .padding(.leading, 14)
                                .background(Color.surfaceContainerLow.opacity(0.45))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .padding(.top, 8)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)

                        if comment.id != commentsViewModel.comments.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(10)
                .background(Color.surfaceContainerLowest)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private var commentInputBar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 10) {
                TextField("Add a comment...", text: $commentText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.surfaceContainerLowest)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Button(action: submitComment) {
                    if commentsViewModel.isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .frame(width: 22, height: 22)
                    } else {
                        Text("Send")
                            .fontWeight(.semibold)
                            .foregroundColor(.primaryBrand)
                    }
                }
                .disabled(commentsViewModel.isSubmitting)
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 12)
            .background(Color.surfaceContainer)
        }
    }

    private var startCookingButton: some View {
        VStack(spacing: 14) {
            RemoteImageView(urlString: ctaIllustrationURL)
                .frame(width: 180, height: 180)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.surfaceContainerLowest, lineWidth: 8)
                )
                .rotationEffect(.degrees(3))
                .shadow(color: .onSurface.opacity(0.14), radius: 12, x: 0, y: 6)

            Button(action: {}) {
                HStack(spacing: 8) {
                    Image(systemName: "play.circle.fill")
                        .font(.title3)
                    Text("Start Cooking Mode")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                }
                .foregroundColor(.onPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.primaryBrand, Color(hex: 0xff7a35)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color.primaryBrand.opacity(0.24), radius: 14, x: 0, y: 8)
            }
        }
        .padding(.top, 12)
    }

    private var decorativeBackgroundSymbols: some View {
        VStack {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.outlineVariant.opacity(0.2))
                    .font(.title2)
                Spacer()
                Image(systemName: "leaf")
                    .foregroundColor(.outlineVariant.opacity(0.2))
                    .font(.title3)
            }
            .padding(.horizontal, 20)
            .padding(.top, 92)

            Spacer()
        }
        .allowsHitTesting(false)
    }

    private var displayCookingMinutes: Int {
        if viewModel.recipe.cookingTimeMinutes > 0 {
            return viewModel.recipe.cookingTimeMinutes
        }

        return max(20, viewModel.recipe.steps.count * 8 + 10)
    }

    private var difficultyLabel: String {
        let normalized = viewModel.recipe.difficulty.trimmingCharacters(in: .whitespacesAndNewlines)
        if !normalized.isEmpty {
            return normalized
        }

        let stepCount = viewModel.recipe.steps.count
        if stepCount <= 4 { return "Easy" }
        if stepCount <= 7 { return "Intermediate" }
        return "Hard"
    }

    private var formattedLikes: String {
        if viewModel.recipe.likes >= 1000 {
            let shortValue = Double(viewModel.recipe.likes) / 1000.0
            return String(format: "%.1fk", shortValue)
        }

        return "\(viewModel.recipe.likes)"
    }

    private func submitComment() {
        let trimmed = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        commentsViewModel.addComment(
            recipeId: viewModel.recipe.id,
            text: trimmed,
            currentUser: authViewModel.currentUser
        ) { success in
            if success {
                commentText = ""
            }
        }
    }

    private func toggleReplyComposer(for commentId: String) {
        if replyingToCommentId == commentId {
            replyingToCommentId = nil
            return
        }

        replyingToCommentId = commentId
    }

    private func submitReply(for commentId: String) {
        let replyText = replyDraftsByCommentId[commentId] ?? ""
        let trimmed = replyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        commentsViewModel.addReply(
            recipeId: viewModel.recipe.id,
            parentCommentId: commentId,
            text: trimmed,
            currentUser: authViewModel.currentUser
        ) { success in
            if success {
                replyDraftsByCommentId[commentId] = ""
                replyingToCommentId = nil
            }
        }
    }

    private func commentTimeString(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct RecipeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleRecipe = CookLoop.Recipe(
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