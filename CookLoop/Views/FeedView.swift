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
    @State private var selectedFeedMode: RecipeViewModel.FeedMode = .global
    @State private var selectedFilter: FeedFilterOption = .all
    @State private var selectedSort: FeedSortOption = .newest
    @State private var userNamesById: [String: String] = [:]
    @State private var selectedRepostItem: RecipeViewModel.FeedItem?
    @State private var showRepostOptions = false
    @State private var showQuoteSheet = false
    @State private var quoteText = ""
    @State private var selectedRecipe: CookLoop.Recipe?
    @State private var showRecipeDetail = false
    @State private var selectedUserId: String = ""
    @State private var showUserProfile = false
    @State private var showSearch = false

    private let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            ZStack {
                feedBackground

                VStack(spacing: 0) {
                    topBar

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            if filteredSortedFeedItems.isEmpty {
                                Text("No recipes match your current filter.")
                                    .font(.subheadline)
                                    .foregroundColor(.onSurfaceVariant)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 2)
                            }

                            ForEach(filteredSortedFeedItems) { item in
                                let recipe = item.recipe
                                RecipeCardView(
                                    recipe: recipe,
                                    username: userNamesById[recipe.userId] ?? "Cook",
                                    isLiked: viewModel.likesByRecipeId[recipe.id] ?? false,
                                    onLike: { viewModel.toggleLike(for: recipe) },
                                    isBookmarked: bookmarkViewModel.isSaved(recipeId: recipe.id),
                                    onBookmarkTap: { bookmarkViewModel.toggleSaved(recipe: recipe) },
                                    onRepostTap: {
                                        selectedRepostItem = item
                                        showRepostOptions = true
                                    },
                                    onUserTap: {
                                        selectedUserId = recipe.userId
                                        showUserProfile = true
                                    },
                                    onCardTap: {
                                        viewModel.markRecipeAsSeen(recipe.id)
                                        selectedRecipe = recipe
                                        showRecipeDetail = true
                                    },
                                    liveBadgeText: liveBadgeText(for: recipe.id),
                                    repostedByText: repostedByText(for: item),
                                    quoteText: item.quoteComment,
                                    postDateText: postDateLabel(for: item.createdAt)
                                )
                                .onAppear {
                                    fetchUserNameIfNeeded(for: recipe.userId)
                                    if let repostedBy = item.repostedByUserId {
                                        fetchUserNameIfNeeded(for: repostedBy)
                                    }
                                }
                            }

                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 18)

                        if !viewModel.errorMessage.isEmpty {
                            Text(viewModel.errorMessage)
                                .foregroundColor(.red)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.surfaceContainerLowest)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                        }
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
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            viewModel.startListeningToFeed(mode: selectedFeedMode)
            bookmarkViewModel.startListening()
        }
        .onChange(of: selectedFeedMode) { newMode in
            viewModel.startListeningToFeed(mode: newMode)
        }
        .onDisappear {
            viewModel.stopListeningToRecipes()
        }
        .actionSheet(isPresented: $showRepostOptions) {
            ActionSheet(
                title: Text("Share Recipe"),
                buttons: [
                    .default(Text("Repost")) {
                        submitRepost(with: nil)
                    },
                    .default(Text("Quote")) {
                        showQuoteSheet = true
                    },
                    .cancel {
                        selectedRepostItem = nil
                    }
                ]
            )
        }
        .sheet(isPresented: $showQuoteSheet) {
            quoteComposerSheet
        }
        .sheet(isPresented: $showSearch) {
            SearchRecipesSheet()
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
                Text("CookLoop.Recipe unavailable")
            }
        }
    }

    private func liveBadgeText(for recipeId: String) -> String? {
        if viewModel.newlyAddedRecipeIDs.contains(recipeId) {
            return "New"
        }

        if viewModel.hasNewCommentActivityByRecipeId[recipeId] == true {
            return "New comment"
        }

        return nil
    }

    private func repostedByText(for item: RecipeViewModel.FeedItem) -> String? {
        guard let repostedByUserId = item.repostedByUserId else { return nil }
        let name = userNamesById[repostedByUserId] ?? "Someone"
        return "\(name) reposted"
    }

    private var topBar: some View {
        VStack(spacing: 12) {
            AppTopBar(onTrailingTap: { showSearch = true })

            HStack(spacing: 8) {
                Picker("Feed Type", selection: $selectedFeedMode) {
                    Text("For You").tag(RecipeViewModel.FeedMode.global)
                    Text("Following").tag(RecipeViewModel.FeedMode.following)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding(4)
            .background(Color.surfaceContainer.opacity(0.85))
            .clipShape(Capsule())
            .frame(maxWidth: .infinity, alignment: .center)

            HStack(spacing: 8) {
                Menu {
                    ForEach(FeedFilterOption.allCases, id: \.rawValue) { option in
                        Button(action: { selectedFilter = option }) {
                            Label(option.title, systemImage: selectedFilter == option ? "checkmark.circle.fill" : "circle")
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text("Filter: \(selectedFilter.title)")
                            .lineLimit(1)
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.onSurface)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.surfaceContainer)
                    .clipShape(Capsule())
                }

                Menu {
                    ForEach(FeedSortOption.allCases, id: \.rawValue) { option in
                        Button(action: { selectedSort = option }) {
                            Label(option.title, systemImage: selectedSort == option ? "checkmark.circle.fill" : "circle")
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.arrow.down.circle")
                        Text("Sort: \(selectedSort.title)")
                            .lineLimit(1)
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.onSurface)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.surfaceContainer)
                    .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(Color.appBackground.opacity(0.95))
    }

    private var filteredSortedFeedItems: [RecipeViewModel.FeedItem] {
        let filtered = viewModel.feedItems.filter { item in
            switch selectedFilter {
            case .all:
                return true
            case .easyOnly:
                return item.recipe.difficulty.lowercased() == "easy"
            case .quickMeals:
                return item.recipe.cookingTimeMinutes <= 30
            case .bookmarked:
                return bookmarkViewModel.isSaved(recipeId: item.recipe.id)
            }
        }

        switch selectedSort {
        case .newest:
            return filtered.sorted { $0.createdAt > $1.createdAt }
        case .oldest:
            return filtered.sorted { $0.createdAt < $1.createdAt }
        case .mostLiked:
            return filtered.sorted { lhs, rhs in
                if lhs.recipe.likes == rhs.recipe.likes {
                    return lhs.createdAt > rhs.createdAt
                }
                return lhs.recipe.likes > rhs.recipe.likes
            }
        }
    }

    private var feedBackground: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 20))
                        .foregroundColor(.outlineVariant.opacity(0.35))
                    Spacer()
                    Image(systemName: "flame.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.outlineVariant.opacity(0.35))
                }
                .padding(.horizontal, 24)
                .padding(.top, 70)

                Spacer()

                HStack {
                    Image(systemName: "leaf")
                        .font(.system(size: 18))
                        .foregroundColor(.outlineVariant.opacity(0.3))
                    Spacer()
                    Image(systemName: "birthday.cake")
                        .font(.system(size: 20))
                        .foregroundColor(.outlineVariant.opacity(0.3))
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 130)
            }
        }
    }

    private var quoteComposerSheet: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Add your thoughts")
                    .font(.headline)
                    .foregroundColor(.onSurface)

                TextEditor(text: $quoteText)
                    .padding(10)
                    .background(Color.surfaceContainerLow)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(minHeight: 140)

                Spacer()
            }
            .padding(16)
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Quote Repost")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        quoteText = ""
                        selectedRepostItem = nil
                        showQuoteSheet = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        submitRepost(with: quoteText)
                        quoteText = ""
                        showQuoteSheet = false
                    }
                }
            }
        }
    }

    private func submitRepost(with comment: String?) {
        guard let item = selectedRepostItem else { return }
        viewModel.createRepost(for: item.recipe, comment: comment)
        selectedRepostItem = nil
    }

    private func postDateLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy • h:mm a"
        return formatter.string(from: date)
    }
}

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
}

private enum FeedFilterOption: String, CaseIterable {
    case all
    case easyOnly
    case quickMeals
    case bookmarked

    var title: String {
        switch self {
        case .all:
            return "All"
        case .easyOnly:
            return "Easy"
        case .quickMeals:
            return "Quick ≤ 30m"
        case .bookmarked:
            return "Bookmarked"
        }
    }
}

private enum FeedSortOption: String, CaseIterable {
    case newest
    case oldest
    case mostLiked

    var title: String {
        switch self {
        case .newest:
            return "Newest"
        case .oldest:
            return "Oldest"
        case .mostLiked:
            return "Most Liked"
        }
    }
}
