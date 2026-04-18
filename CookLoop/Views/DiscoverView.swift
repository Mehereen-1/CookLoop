
import SwiftUI
import FirebaseFirestore

struct DiscoverView: View {
    @State private var showSearch = false
    @State private var discoverSearchText = ""
    @StateObject private var discoverViewModel = DiscoverViewModel()

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    header
                    searchBar
                    curatedCollections
                    trendingNowSection
                    Spacer().frame(height: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.outlineVariant.opacity(0.35), lineWidth: 1)
            )
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showSearch) {
            SearchRecipesSheet()
        }
        .onAppear {
            if discoverViewModel.recipes.isEmpty {
                discoverViewModel.fetchRecipes(searchTerm: "chicken")
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
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
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.primaryBrand)
                .padding(.leading, 16)

            TextField("Search for magic ingredients...", text: $discoverSearchText, onCommit: {
                showSearch = true
            })
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.onSurface)
                .padding(.vertical, 16)

            Image(systemName: "slider.horizontal.3")
                .foregroundColor(.outlineVariant)
                .padding(.trailing, 16)
        }
        .background(Color.surfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var curatedCollections: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Text("Curated Collections")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(.onSurface)

                Text("✨")
                    .font(.system(size: 28))
            }

            VStack(spacing: 16) {
                NavigationLink(destination: TagRecipesView(tag: "Cozy Breakfasts")) {
                    ZStack(alignment: .bottomTrailing) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("MORNING MAGIC")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.onTertiaryContainer)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.tertiaryContainer)
                                .clipShape(Capsule())
                                .padding(.bottom, 8)

                            Text("Cozy\nBreakfasts")
                                .font(.system(size: 36, weight: .heavy, design: .rounded))
                                .foregroundColor(.onSurface)
                                .lineSpacing(0)

                            Text("Start your day with heart-warming,\nwhimsical morning treats.")
                                .font(.system(size: 14))
                                .foregroundColor(.onSurfaceVariant)
                                .padding(.top, 4)

                            Spacer()
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity, alignment: .leading)

                        RemoteImageView(urlString: "https://lh3.googleusercontent.com/aida-public/AB6AXuDIZl9qLikcBH4vOG8Tk4XGF6rE9Yia0Lb8UQXFfkIi7FZGwUu22AIaglBaCox6NtJZGPw_rHK09Z2JFWzDvYO7-TbFg72pWKMhsH4d0mBaEKGNInHpbSWy5WaMnznaIj9uYPoI9lFqYjOR7pipqhkoXddod_z8iOLykz36DJRzWGsoCbXO20dR_lFPkcrIdjvWg3r57gANkhFTchq5EODJZReTvJrKr6OxG8283-W7RqIk8Qt-qC4HQ8bREYGXVhkYKaL9ylVNB_Q")
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .offset(x: 20, y: 30)
                    }
                    .frame(height: 240)
                    .background(Color.surfaceContainerLow)
                    .clipShape(RoundedRectangle(cornerRadius: 32))
                }
                .buttonStyle(PlainButtonStyle())

                NavigationLink(destination: TagRecipesView(tag: "Spicy Dinners")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Spicy Dinners")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundColor(.onSurface)

                        Spacer()
                        Image(systemName: "flame.fill")
                            .foregroundColor(Color(hex: 0xff7a35))
                            .font(.system(size: 24))
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    RemoteImageView(urlString: "https://lh3.googleusercontent.com/aida-public/AB6AXuBw_aLHdPGRf-ziwXoxq3zjYUxjycW5A7GtcfoeMcFS9FBtyicw_gQmZ71p9DEkqAN9Dd6awMLrBzj6Wj3WSSWiti0V01aVlKLxKh1UJ8cuiZEzPDPGC_5dODiViYXXFSiuRhTaAlO5X3GCNE0rQh4tbfdxFaEOwey-AOCKPC2LznsPISqhZMCY-9id7KaGwb9jqefznh4d4BN2-K1ocTSNSTImG_TNJCx4gFQR2w3Lye8abuI96PnsusIyykr0JQ0Jbi5I-QJC3Yk")
                        .frame(width: 140, height: 140)
                        .clipShape(Circle())
                        .offset(x: 10, y: 10)
                }
                .frame(height: 120)
                .background(Color.secondaryContainer)
                .clipShape(RoundedRectangle(cornerRadius: 32))
                .buttonStyle(PlainButtonStyle())

                NavigationLink(destination: TagRecipesView(tag: "Sweet Treats")) {
                    ZStack(alignment: .trailing) {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Sweet Treats")
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                                .foregroundColor(.onTertiaryContainer)

                            Text("Tap to explore")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.onTertiaryContainer)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.surfaceContainerLowest.opacity(0.8))
                                .clipShape(Capsule())
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)

                        RemoteImageView(urlString: "https://lh3.googleusercontent.com/aida-public/AB6AXuAyJWXGboYJsC_zeYHiCuSv9253nHYMZ1oTd3i89Pot9jnXxlP-T0Tw6aJqDztggineznIzSaPkC8umS-X77GSJxhEpd0k6cWOuGJ_iC3-KoI4JJhZ22TMDf8A8rGH424Gw_aMPQXRNaKJPop9z6MyTiiGOcmgOWHRFJq5gdUPBKOwp8VgcHOdCZxO8IynJgkD4wlnjgMivobLK5_iu5bxujX1FkrqYWO0BlsIdW38vSD6-HwM321TE9fOMgBPTHYCoAXXOB6SqRt4")
                            .frame(width: 120, height: 120)
                    }
                    .frame(height: 140)
                    .background(Color.tertiaryContainer)
                    .clipShape(RoundedRectangle(cornerRadius: 32))
                }
                .buttonStyle(PlainButtonStyle())

                NavigationLink(destination: TagRecipesView(tag: "Quick Fixes")) {
                    HStack {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("15-Min\nQuick\nFixes")
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                                .foregroundColor(.onSurface)

                            Text("When the\nstory needs to\nmove fast!")
                                .font(.system(size: 14))
                                .foregroundColor(.onSurfaceVariant)

                            HStack {
                                Text("Fast")
                                    .font(.system(size: 12, weight: .bold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.8))
                                    .clipShape(Capsule())

                                Text("Easy")
                                    .font(.system(size: 12, weight: .bold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.8))
                                    .clipShape(Capsule())
                            }
                        }

                        Spacer()

                        Circle()
                            .fill(Color.primaryBrand.opacity(0.1))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "timer")
                                    .font(.system(size: 40))
                                    .foregroundColor(.primaryBrand)
                            )
                    }
                    .padding(24)
                    .background(Color.surfaceContainer)
                    .clipShape(RoundedRectangle(cornerRadius: 32))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private var trendingNowSection: some View {
        VStack(spacing: 16) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Classic Recipies")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(.onSurface)

                    Text("All time classic")
                        .font(.system(size: 14))
                        .foregroundColor(.onSurfaceVariant)
                }

                Spacer()

                NavigationLink(destination: TrendingRecipesListView(recipes: discoverViewModel.recipes)) {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(.system(size: 14, weight: .bold))
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.primaryBrand)
                }
                .buttonStyle(PlainButtonStyle())
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    if discoverViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .primaryBrand))
                            .frame(width: 260, height: 220)
                    } else {
                        ForEach(Array(discoverViewModel.recipes.prefix(12))) { recipe in
                            NavigationLink(destination: APIDetailView(recipe: recipe)) {
                                VStack(alignment: .leading, spacing: 12) {
                                    ZStack(alignment: .topTrailing) {
                                        RemoteImageView(urlString: recipe.strMealThumb)
                                            .frame(width: 260, height: 180)
                                            .clipShape(RoundedRectangle(cornerRadius: 24))

                                        Text("API")
                                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                                            .foregroundColor(.onPrimary)
                                            .padding(.horizontal, 9)
                                            .padding(.vertical, 4)
                                            .background(Color.primaryBrand)
                                            .clipShape(Capsule())
                                            .padding(12)
                                    }

                                    Text(recipe.strMeal)
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(.onSurface)
                                        .lineLimit(2)

                                    HStack(spacing: 8) {
                                        if let category = recipe.strCategory, !category.isEmpty {
                                            Text(category)
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.onSecondaryContainer)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 5)
                                                .background(Color.secondaryContainer)
                                                .clipShape(Capsule())
                                        }

                                        if let area = recipe.strArea, !area.isEmpty {
                                            Text(area)
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.onTertiaryContainer)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 5)
                                                .background(Color.tertiaryContainer)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                                .padding(16)
                                .background(Color.surfaceContainerLowest)
                                .clipShape(RoundedRectangle(cornerRadius: 32))
                                .shadow(color: .onSurface.opacity(0.06), radius: 20, x: 0, y: 12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 2)
                .padding(.bottom, 20)
            }
            .padding(.horizontal, -20)

            if !discoverViewModel.errorMessage.isEmpty {
                Text(discoverViewModel.errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

private struct TagRecipesView: View {
    @Environment(\.presentationMode) var presentationMode
    let tag: String

    @State private var recipes: [CookLoop.Recipe] = []
    @State private var isLoading = false
    @State private var errorMessage = ""

    private let db = Firestore.firestore()

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    AppTopBar(
                        subtitle: "Recipes tagged \"\(tag)\"",
                        showsBackButton: true,
                        trailingSystemIcon: nil,
                        onBackTap: { presentationMode.wrappedValue.dismiss() }
                    )

                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .primaryBrand))
                            Spacer()
                        }
                    } else if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    } else if recipes.isEmpty {
                        Text("No recipes found for this collection yet.")
                            .foregroundColor(.onSurfaceVariant)
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(recipes) { recipe in
                                NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                    HStack(spacing: 10) {
                                        Group {
                                            if !recipe.imageUrl.isEmpty {
                                                RemoteImageView(urlString: recipe.imageUrl)
                                            } else {
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(Color.surfaceContainer)
                                                    .overlay(
                                                        Image(systemName: "flame.fill")
                                                            .foregroundColor(.primaryBrand)
                                                    )
                                            }
                                        }
                                        .frame(width: 64, height: 64)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(recipe.title)
                                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                                .foregroundColor(.onSurface)
                                                .lineLimit(2)

                                            Text("\(max(5, recipe.cookingTimeMinutes)) mins • \(recipe.difficulty)")
                                                .font(.caption)
                                                .foregroundColor(.onSurfaceVariant)
                                        }

                                        Spacer()
                                    }
                                    .padding(10)
                                    .background(Color.surfaceContainerLowest)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            loadRecipes()
        }
    }

    private func loadRecipes() {
        isLoading = true
        errorMessage = ""

        db.collection("recipes")
            .whereField("tags", arrayContains: tag)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    self.isLoading = false

                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        return
                    }

                    let fetched = snapshot?.documents.compactMap { doc in
                        RecipeViewModel.parseRecipe(id: doc.documentID, data: doc.data())
                    } ?? []

                    self.recipes = fetched.sorted { $0.createdAt > $1.createdAt }
                }
            }
    }
}

private struct TrendingRecipesListView: View {
    @Environment(\.presentationMode) var presentationMode
    let recipes: [APIRecipe]
    @State private var searchText = ""

    private var filteredRecipes: [APIRecipe] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return recipes }

        return recipes.filter { recipe in
            let title = recipe.strMeal.lowercased()
            let category = (recipe.strCategory ?? "").lowercased()
            let area = (recipe.strArea ?? "").lowercased()
            return title.contains(query) || category.contains(query) || area.contains(query)
        }
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    AppTopBar(
                        subtitle: "Classic recipies",
                        showsBackButton: true,
                        trailingSystemIcon: nil,
                        onBackTap: { presentationMode.wrappedValue.dismiss() }
                    )

                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.primaryBrand)
                        TextField("Search classics by name, category, or region...", text: $searchText)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .foregroundColor(.onSurface)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.surfaceContainerLowest)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    if recipes.isEmpty {
                        Text("No classic recipes available right now.")
                            .foregroundColor(.onSurfaceVariant)
                    } else if filteredRecipes.isEmpty {
                        Text("No classic recipes matched your search.")
                            .foregroundColor(.onSurfaceVariant)
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(filteredRecipes) { recipe in
                                NavigationLink(destination: APIDetailView(recipe: recipe)) {
                                    HStack(spacing: 10) {
                                        RemoteImageView(urlString: recipe.strMealThumb)
                                            .frame(width: 64, height: 64)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(recipe.strMeal)
                                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                                .foregroundColor(.onSurface)
                                                .lineLimit(2)

                                            let category = recipe.strCategory?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                                            let area = recipe.strArea?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                                            Text([category, area].filter { !$0.isEmpty }.joined(separator: " • "))
                                                .font(.caption)
                                                .foregroundColor(.onSurfaceVariant)
                                                .lineLimit(1)
                                        }

                                        Spacer()
                                    }
                                    .padding(10)
                                    .background(Color.surfaceContainerLowest)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
}

struct DiscoverView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverView()
    }
}
