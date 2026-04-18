//
//  ProfileView.swift
//  CookLoop
//
//  Created by Ayesha Meherin on 26/3/26.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ProfileView: View {
        @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel = ProfileViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var bookmarkViewModel: BookmarkViewModel
    @AppStorage(ThemeStore.selectedThemeKey) private var selectedThemeKey = AppTheme.warmClassic.rawValue

    @State private var showEditProfile = false
    @State private var selectedRecipe: CookLoop.Recipe?
    @State private var showRecipeDetail = false
    @State private var selectedUserId: String = ""
    @State private var showUserProfile = false
    @State private var selectedConnectionsType: ConnectionsType?
    @State private var showConnectionsList = false
    @State private var selectedSection: ProfileSection = .myRecipes
    @State private var userNamesById: [String: String] = [:]
    @State private var showSearch = false
    @State private var recipeToEdit: CookLoop.Recipe?
    @State private var recipeToDelete: CookLoop.Recipe?
    @State private var showDeleteRecipeAlert = false

    private let db = Firestore.firestore()

    var userId: String

    private var isCurrentUser: Bool {
        if let sessionUID = Auth.auth().currentUser?.uid {
            return sessionUID == userId
        }

        return authViewModel.currentUser?.id == userId
    }

    private var displayedRecipes: [CookLoop.Recipe] {
        if isCurrentUser && selectedSection == .savedRecipes {
            return bookmarkViewModel.savedRecipes
        }
        return viewModel.recipes
    }

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    profileTopBar

                    profileHeroSection
                    statsSection
                    sectionHeader
                    recipesGridSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 0)
                .padding(.bottom, 24)
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

            NavigationLink(
                destination: connectionsDestination,
                isActive: $showConnectionsList
            ) {
                EmptyView()
            }
            .hidden()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .onAppear {
            viewModel.fetchUser(userId: userId)
            viewModel.fetchUserRecipes(userId: userId)
            viewModel.fetchFollowStats(userId: userId)

            if isCurrentUser {
                bookmarkViewModel.startListening()
            } else {
                viewModel.checkIfFollowing(targetUserId: userId)
            }
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView(viewModel: viewModel)
        }
        .sheet(isPresented: $showSearch) {
            SearchRecipesSheet()
        }
        .sheet(item: $recipeToEdit) { recipe in
            EditRecipeSheet(recipe: recipe) { title, imageUrl, ingredients, steps, cookingTimeMinutes, difficulty, tags in
                viewModel.updateRecipe(
                    recipeId: recipe.id,
                    title: title,
                    imageUrl: imageUrl,
                    ingredients: ingredients,
                    steps: steps,
                    cookingTimeMinutes: cookingTimeMinutes,
                    difficulty: difficulty,
                    tags: tags
                ) { success in
                    if success {
                        viewModel.fetchUserRecipes(userId: userId)
                    }
                }
            }
        }
        .alert(isPresented: $showDeleteRecipeAlert) {
            Alert(
                title: Text("Delete Recipe?"),
                message: Text("This will permanently remove the recipe."),
                primaryButton: .destructive(Text("Delete")) {
                    if let recipe = recipeToDelete {
                        viewModel.deleteRecipe(recipeId: recipe.id) { success in
                            if success {
                                viewModel.fetchUserRecipes(userId: userId)
                            }
                        }
                    }
                    recipeToDelete = nil
                },
                secondaryButton: .cancel {
                    recipeToDelete = nil
                }
            )
        }
    }

    private var profileSubtitle: String {
        if isCurrentUser {
            return "Your kitchen, your story"
        }

        let name = viewModel.user?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if name.isEmpty {
            return "Chef profile"
        }

        return "\(name)'s kitchen story"
    }

    private var profileTopBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                if !isCurrentUser {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.primaryBrand)
                            .frame(width: 34, height: 34)
                            .background(Color.surfaceContainerLowest)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.outlineVariant.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Image(systemName: "book.pages.fill")
                    .foregroundColor(.primaryBrand)
                    .font(.system(size: 24))

                Text("CookLoop")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primaryBrand)

                Spacer()

                Button(action: { showSearch = true }) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.primaryBrand)
                        .font(.system(size: 20))
                }
                .buttonStyle(PlainButtonStyle())
            }

            Text(profileSubtitle)
                .font(.subheadline)
                .foregroundColor(.onSurfaceVariant)
        }
    }

    private var profileHeroSection: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .topTrailing) {
                profileImageView
                    .frame(width: 132, height: 132)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.surfaceContainerLowest, lineWidth: 6)
                    )
                    .shadow(color: .onSurface.opacity(0.1), radius: 10, x: 0, y: 6)

                Circle()
                    .fill(Color.tertiaryContainer)
                    .frame(width: 42, height: 42)
                    .overlay(
                        Image(systemName: "flame.fill")
                            .foregroundColor(.onTertiaryContainer)
                    )
                    .offset(x: 12, y: -12)
            }

            Text(viewModel.user?.name.isEmpty == false ? viewModel.user?.name ?? "Cook" : "Cook")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundColor(.onSurface)

            Text((viewModel.user?.bio ?? "").isEmpty ? "Sharing kitchen stories one recipe at a time." : (viewModel.user?.bio ?? ""))
                .font(.subheadline)
                .foregroundColor(.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 8)

            gamificationSection

            if isCurrentUser {
                themeSelectorSection
            }

            actionButtonsRow
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private var gamificationSection: some View {
        if let user = viewModel.user {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primaryBrand)

                    Text("\(user.level) · XP \(user.xp)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.onSurface)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.surfaceContainerLowest)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.outlineVariant.opacity(0.35), lineWidth: 1)
                )

                if !user.badges.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(user.badges, id: \.self) { badge in
                                Text(badge)
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.onTertiaryContainer)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background(Color.tertiaryContainer)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
    }

    private var profileImageView: some View {
        Group {
            if let profileImage = viewModel.user?.profileImage,
               !profileImage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                RemoteImageView(urlString: profileImage)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.surfaceContainer)
                    Image(systemName: "person.fill")
                        .font(.system(size: 46, weight: .bold))
                        .foregroundColor(.primaryBrand)
                }
            }
        }
    }

    private var actionButtonsRow: some View {
        HStack(spacing: 10) {
            if isCurrentUser {
                Button(action: {
                    showEditProfile = true
                }) {
                    Label("Edit Profile", systemImage: "square.and.pencil")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.primaryBrand)
                        .foregroundColor(.onPrimary)
                        .clipShape(Capsule())
                }

                Button(action: {
                    authViewModel.signOut()
                }) {
                    Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.secondaryContainer)
                        .foregroundColor(.onSecondaryContainer)
                        .clipShape(Capsule())
                }
            } else {
                Button(action: {
                    viewModel.toggleFollow(targetUserId: userId)
                }) {
                    Label(viewModel.isFollowing ? "Unfollow" : "Follow", systemImage: viewModel.isFollowing ? "person.badge.minus" : "person.badge.plus")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(viewModel.isFollowing ? Color.surfaceContainer : Color.primaryBrand)
                        .foregroundColor(viewModel.isFollowing ? .onSurface : .onPrimary)
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var themeSelectorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Theme")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.onSurfaceVariant)

            HStack(spacing: 8) {
                ForEach(AppTheme.allCases, id: \.rawValue) { theme in
                    Button(action: {
                        selectedThemeKey = theme.rawValue
                    }) {
                        VStack(spacing: 6) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(primarySwatchColor(for: theme))
                                    .frame(width: 10, height: 10)
                                Circle()
                                    .fill(secondarySwatchColor(for: theme))
                                    .frame(width: 10, height: 10)
                                Circle()
                                    .fill(tertiarySwatchColor(for: theme))
                                    .frame(width: 10, height: 10)
                            }

                            Text(theme.title)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.onSurface)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(selectedThemeKey == theme.rawValue ? Color.secondaryContainer : Color.surfaceContainerLowest)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.outlineVariant.opacity(selectedThemeKey == theme.rawValue ? 0.55 : 0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func primarySwatchColor(for theme: AppTheme) -> Color {
        switch theme {
        case .warmClassic:
            return Color(hex: 0x9e3d00)
        case .mintGarden:
            return Color(hex: 0x1e7d52)
        case .oceanBreeze:
            return Color(hex: 0x0b5f93)
        case .light:
            return Color(hex: 0x4C662B)
        case .dark:
            return Color(hex: 0xB1D18A)
        case .wodlot:
            return Color(hex: 0x8B2C2D)
        }
    }

    private func secondarySwatchColor(for theme: AppTheme) -> Color {
        switch theme {
        case .warmClassic:
            return Color(hex: 0xfed3c7)
        case .mintGarden:
            return Color(hex: 0xc9f0dd)
        case .oceanBreeze:
            return Color(hex: 0xcbe7fb)
        case .light:
            return Color(hex: 0xDCE7C8)
        case .dark:
            return Color(hex: 0x404A33)
        case .wodlot:
            return Color(hex: 0x8A9A7B)
        }
    }

    private func tertiarySwatchColor(for theme: AppTheme) -> Color {
        switch theme {
        case .warmClassic:
            return Color(hex: 0xfedba3)
        case .mintGarden:
            return Color(hex: 0xdef3c7)
        case .oceanBreeze:
            return Color(hex: 0xd7e3ff)
        case .light:
            return Color(hex: 0xBCECE7)
        case .dark:
            return Color(hex: 0x1F4E4B)
        case .wodlot:
            return Color(hex: 0xB87B4A)
        }
    }

    private var statsSection: some View {
        Group {
            if isCurrentUser {
                HStack(spacing: 10) {
                    statCard(value: "\(viewModel.recipes.count)", label: "Stories")
                        .rotationEffect(.degrees(-1.2))
                    statButtonCard(value: compactNumber(viewModel.followersCount), label: "Followers", type: .followers)
                        .offset(y: 5)
                    statButtonCard(value: compactNumber(viewModel.followingCount), label: "Following", type: .following)
                        .rotationEffect(.degrees(1.2))
                    statCard(value: compactNumber(bookmarkViewModel.savedRecipes.count), label: "Saves")
                        .offset(y: -3)
                }
            } else {
                HStack(spacing: 10) {
                    statCard(value: compactNumber(viewModel.recipes.count), label: "Recipes")
                    statButtonCard(value: compactNumber(viewModel.followersCount), label: "Followers", type: .followers)
                    statButtonCard(value: compactNumber(viewModel.followingCount), label: "Following", type: .following)
                }
            }
        }
        .padding(.top, 4)
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 25, weight: .black, design: .rounded))
                .foregroundColor(.primaryBrand)
            Text(label)
                .font(.caption)
                .foregroundColor(.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func statButtonCard(value: String, label: String, type: ConnectionsType) -> some View {
        Button(action: {
            selectedConnectionsType = type
            showConnectionsList = true
        }) {
            statCard(value: value, label: label)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var sectionHeader: some View {
        VStack(spacing: 10) {
            HStack {
                Text(sectionTitle)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.onSurface)
                Spacer()
            }

            if isCurrentUser {
                HStack(spacing: 8) {
                    sectionButton(title: "My Recipes", section: .myRecipes)
                    sectionButton(title: "Saved Recipes", section: .savedRecipes)
                }
                .padding(6)
                .background(Color.surfaceContainerLowest)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.outlineVariant.opacity(0.35), lineWidth: 1)
                )
            }
        }
    }

    private var sectionTitle: String {
        if isCurrentUser && selectedSection == .savedRecipes {
            return "Saved Recipes"
        }

        if isCurrentUser {
            return "My Recipes"
        }

        let name = viewModel.user?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if name.isEmpty {
            return "Shared Recipes"
        }

        return "\(name)'s Recipes"
    }

    private var recipesGridSection: some View {
        Group {
            if displayedRecipes.isEmpty {
                Text(isCurrentUser && selectedSection == .savedRecipes ? "No saved recipes yet." : "No recipes yet.")
                    .font(.subheadline)
                    .foregroundColor(.onSurfaceVariant)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
            } else {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(displayedRecipes) { recipe in
                        recipeStoryCard(recipe)
                            .onAppear {
                                fetchUserNameIfNeeded(for: recipe.userId)
                            }
                    }
                }
            }
        }
    }

    private func recipeStoryCard(_ recipe: CookLoop.Recipe) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topLeading) {
                Button(action: {
                    selectedRecipe = recipe
                    showRecipeDetail = true
                }) {
                    ZStack(alignment: .topTrailing) {
                        Group {
                            if !recipe.imageUrl.isEmpty {
                                RemoteImageView(urlString: recipe.imageUrl)
                            } else if let imageData = recipe.legacyImageData,
                                      let data = Data(base64Encoded: imageData),
                                      let image = UIImage(data: data) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Rectangle()
                                    .fill(Color.secondaryContainer.opacity(0.4))
                            }
                        }
                        .frame(height: 140)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        Text("\(max(5, recipe.cookingTimeMinutes)) mins")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.onPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.primaryBrand.opacity(0.9))
                            .clipShape(Capsule())
                            .padding(8)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                if isCurrentUser && selectedSection == .myRecipes {
                    HStack {
                        Menu {
                            Button(action: {
                                recipeToEdit = recipe
                            }) {
                                Label("Modify", systemImage: "square.and.pencil")
                            }

                            Button(action: {
                                recipeToDelete = recipe
                                showDeleteRecipeAlert = true
                            }) {
                                Label("Delete", systemImage: "trash")
                                    .foregroundColor(.red)
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.onSurface)
                                .padding(8)
                                .background(Color.surfaceContainerLowest.opacity(0.9))
                                .clipShape(Circle())
                        }

                        Spacer()
                    }
                    .padding(8)
                }
            }

            Text(recipe.title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.onSurface)
                .lineLimit(2)

            Text(userNamesById[recipe.userId] ?? viewModel.user?.name ?? "Cook")
                .font(.caption)
                .foregroundColor(.onSurfaceVariant)
                .lineLimit(1)

            recipeTags(recipe)

            if isCurrentUser {
                HStack {
                    Spacer()
                    Button(action: {
                        bookmarkViewModel.toggleSaved(recipe: recipe)
                    }) {
                        Image(systemName: bookmarkViewModel.isSaved(recipeId: recipe.id) ? "bookmark.fill" : "bookmark")
                            .foregroundColor(.primaryBrand)
                    }
                }
            }
        }
        .padding(10)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .onSurface.opacity(0.06), radius: 6, x: 0, y: 4)
    }

    private func recipeTags(_ recipe: CookLoop.Recipe) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Array(recipe.tags.prefix(2)), id: \.self) { tag in
                    Text(tag)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.onTertiaryContainer)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.tertiaryContainer)
                        .clipShape(Capsule())
                }
            }
        }
    }

    private func sectionButton(title: String, section: ProfileSection) -> some View {
        Button(action: {
            selectedSection = section

            if section == .myRecipes && viewModel.recipes.isEmpty {
                viewModel.fetchUserRecipes(userId: userId)
            }

            if section == .savedRecipes && isCurrentUser {
                bookmarkViewModel.startListening()
            }
        }) {
            Text(title)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(selectedSection == section ? Color.secondaryContainer : Color.clear)
                .foregroundColor(selectedSection == section ? .onSecondaryContainer : .onSurfaceVariant)
                .clipShape(RoundedRectangle(cornerRadius: 10))
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

    private var connectionsDestination: some View {
        Group {
            if let selectedConnectionsType = selectedConnectionsType {
                UserConnectionsListView(
                    profileUserId: userId,
                    type: selectedConnectionsType
                )
            } else {
                Text("Users unavailable")
            }
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

    private func compactNumber(_ value: Int) -> String {
        if value >= 1000 {
            let short = Double(value) / 1000.0
            return String(format: "%.1fk", short)
        }

        return "\(value)"
    }
}

private struct EditRecipeSheet: View {
    @Environment(\.presentationMode) var presentationMode

    let recipe: CookLoop.Recipe
    let onSave: (String, String, [String], [String], Int, String, [String]) -> Void

    @State private var title: String
    @State private var imageUrl: String
    @State private var ingredientsText: String
    @State private var stepsText: String
    @State private var cookingTimeMinutes: Int
    @State private var difficulty: String
    @State private var tagsText: String

    init(
        recipe: CookLoop.Recipe,
        onSave: @escaping (String, String, [String], [String], Int, String, [String]) -> Void
    ) {
        self.recipe = recipe
        self.onSave = onSave
        _title = State(initialValue: recipe.title)
        _imageUrl = State(initialValue: recipe.imageUrl)
        _ingredientsText = State(initialValue: recipe.ingredients.joined(separator: "\n"))
        _stepsText = State(initialValue: recipe.steps.joined(separator: "\n"))
        _cookingTimeMinutes = State(initialValue: max(5, recipe.cookingTimeMinutes))
        _difficulty = State(initialValue: recipe.difficulty.isEmpty ? "Intermediate" : recipe.difficulty)
        _tagsText = State(initialValue: recipe.tags.joined(separator: ", "))
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Modify Recipe")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundColor(.onSurface)

                        editorTextField(title: "Title", text: $title)
                        editorTextField(title: "Image URL", text: $imageUrl)
                        editorTextEditor(title: "Ingredients (one per line)", text: $ingredientsText, minHeight: 110)
                        editorTextEditor(title: "Steps (one per line)", text: $stepsText, minHeight: 140)
                        editorTextField(title: "Difficulty", text: $difficulty)
                        editorTextField(title: "Tags (comma separated)", text: $tagsText)

                        HStack {
                            Text("Cooking Time")
                                .foregroundColor(.onSurfaceVariant)
                            Spacer()
                            Text("\(cookingTimeMinutes) min")
                                .foregroundColor(.primaryBrand)
                                .fontWeight(.semibold)
                        }

                        Stepper("", value: $cookingTimeMinutes, in: 5...300, step: 5)
                            .labelsHidden()
                    }
                    .padding(16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let ingredients = ingredientsText
                            .components(separatedBy: .newlines)
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }

                        let steps = stepsText
                            .components(separatedBy: .newlines)
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }

                        let tags = tagsText
                            .components(separatedBy: ",")
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }

                        onSave(title, imageUrl, ingredients, steps, cookingTimeMinutes, difficulty, tags)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    private func editorTextField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.onSurfaceVariant)
            TextField(title, text: text)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.surfaceContainerLowest)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func editorTextEditor(title: String, text: Binding<String>, minHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.onSurfaceVariant)
            TextEditor(text: text)
                .frame(minHeight: minHeight)
                .padding(8)
                .background(Color.surfaceContainerLowest)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

private enum ProfileSection {
    case myRecipes
    case savedRecipes
}

private enum ConnectionsType {
    case followers
    case following

    var title: String {
        switch self {
        case .followers:
            return "Followers"
        case .following:
            return "Following"
        }
    }

    var collectionName: String {
        switch self {
        case .followers:
            return "followers"
        case .following:
            return "following"
        }
    }
}

private struct ConnectionUser: Identifiable {
    let id: String
    let name: String
    let bio: String
    let profileImage: String?
}

private struct UserConnectionsListView: View {
        @Environment(\.presentationMode) var presentationMode
    let profileUserId: String
    let type: ConnectionsType

    @State private var users: [ConnectionUser] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var selectedUserId: String = ""
    @State private var showUserProfile = false

    private let db = Firestore.firestore()

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    connectionsTopBar
                    contentView
                }
                .padding(.horizontal, 16)
                .padding(.top, 0)
                .padding(.bottom, 24)
            }

            NavigationLink(
                destination: ProfileView(userId: selectedUserId),
                isActive: $showUserProfile
            ) {
                EmptyView()
            }
            .hidden()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .onAppear {
            loadConnections()
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if isLoading {
            HStack {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .primaryBrand))
                Spacer()
            }
            .padding(.vertical, 24)
            .background(Color.surfaceContainerLowest)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        } else if !errorMessage.isEmpty {
            Text(errorMessage)
                .foregroundColor(.red)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.surfaceContainerLowest)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        } else if users.isEmpty {
            Text("No \(type.title.lowercased()) yet.")
                .foregroundColor(.onSurfaceVariant)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.surfaceContainerLowest)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            LazyVStack(spacing: 10) {
                ForEach(users) { user in
                    Button(action: {
                        selectedUserId = user.id
                        showUserProfile = true
                    }) {
                        HStack(spacing: 10) {
                            avatar(for: user)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.name)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.onSurface)

                                if !user.bio.isEmpty {
                                    Text(user.bio)
                                        .font(.caption)
                                        .foregroundColor(.onSurfaceVariant)
                                        .lineLimit(1)
                                }
                            }

                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.onSurfaceVariant)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.surfaceContainerLowest)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.outlineVariant.opacity(0.28), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    private var connectionsTopBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primaryBrand)
                        .frame(width: 34, height: 34)
                        .background(Color.surfaceContainerLowest)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.outlineVariant.opacity(0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(PlainButtonStyle())

                Image(systemName: "book.pages.fill")
                    .foregroundColor(.primaryBrand)
                    .font(.system(size: 24))

                Text("CookLoop")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primaryBrand)

                Spacer()
            }

            Text(type.title)
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundColor(.onSurface)
        }
    }

    private func avatar(for user: ConnectionUser) -> some View {
        Group {
            if let profileImage = user.profileImage,
               !profileImage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                RemoteImageView(urlString: profileImage)
            } else {
                Circle()
                    .fill(Color.surfaceContainer)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.primaryBrand)
                    )
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(Circle())
    }

    private func loadConnections() {
        isLoading = true
        errorMessage = ""

        db.collection("users")
            .document(profileUserId)
            .collection(type.collectionName)
            .getDocuments { snapshot, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.errorMessage = error.localizedDescription
                    }
                    return
                }

                let ids: [String] = snapshot?.documents.map { doc in
                    if let storedId = doc.data()["userId"] as? String,
                       !storedId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        return storedId
                    }

                    return doc.documentID
                } ?? []

                if ids.isEmpty {
                    DispatchQueue.main.async {
                        self.users = []
                        self.isLoading = false
                    }
                    return
                }

                let group = DispatchGroup()
                var fetchedUsers: [ConnectionUser] = []

                for id in ids {
                    group.enter()
                    db.collection("users").document(id).getDocument { userSnapshot, _ in
                        defer { group.leave() }
                        guard let data = userSnapshot?.data() else { return }

                        let name = (data["name"] as? String ?? "Cook")
                        let bio = (data["bio"] as? String ?? "")
                        let profileImage = data["profileImage"] as? String

                        fetchedUsers.append(
                            ConnectionUser(
                                id: id,
                                name: name,
                                bio: bio,
                                profileImage: profileImage
                            )
                        )
                    }
                }

                group.notify(queue: .main) {
                    let order = Dictionary(uniqueKeysWithValues: ids.enumerated().map { ($0.element, $0.offset) })
                    self.users = fetchedUsers.sorted {
                        (order[$0.id] ?? Int.max) < (order[$1.id] ?? Int.max)
                    }
                    self.isLoading = false
                }
            }
    }
}
