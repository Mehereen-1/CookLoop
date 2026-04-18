//
//  ContentView.swift
//  CookLoop
//
//  Created by Ayesha Meherin on 26/3/26.
//

import SwiftUI
import FirebaseFirestore

enum AppTheme: String, CaseIterable {
    case warmClassic
    case mintGarden
    case oceanBreeze
    case light
    case dark
    case wodlot

    var title: String {
        switch self {
        case .warmClassic:
            return "Warm Classic"
        case .mintGarden:
            return "Mint Garden"
        case .oceanBreeze:
            return "Ocean Breeze"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        case .wodlot:
            return "Wodlot"
        }
    }
}

struct ThemePalette {
    let background: UInt
    let surfaceContainerLow: UInt
    let surfaceContainerLowest: UInt
    let surfaceContainer: UInt
    let primaryBrand: UInt
    let onPrimary: UInt
    let secondaryContainer: UInt
    let onSecondaryContainer: UInt
    let tertiaryContainer: UInt
    let onTertiaryContainer: UInt
    let onSurface: UInt
    let onSurfaceVariant: UInt
    let outlineVariant: UInt
}

enum ThemeStore {
    static let selectedThemeKey = "cookloop.selectedTheme"

    static var selectedTheme: AppTheme {
        let raw = UserDefaults.standard.string(forKey: selectedThemeKey) ?? AppTheme.warmClassic.rawValue
        return AppTheme(rawValue: raw) ?? .warmClassic
    }

    static var palette: ThemePalette {
        switch selectedTheme {
        case .warmClassic:
            return ThemePalette(
                background: 0xfcf6e3,
                surfaceContainerLow: 0xf7f1dc,
                surfaceContainerLowest: 0xffffff,
                surfaceContainer: 0xeee8d3,
                primaryBrand: 0x9e3d00,
                onPrimary: 0xfff0ea,
                secondaryContainer: 0xfed3c7,
                onSecondaryContainer: 0x65473e,
                tertiaryContainer: 0xfedba3,
                onTertiaryContainer: 0x644c21,
                onSurface: 0x312f23,
                onSurfaceVariant: 0x5f5c4d,
                outlineVariant: 0xb2ad9c
            )
        case .mintGarden:
            return ThemePalette(
                background: 0xeff7f1,
                surfaceContainerLow: 0xe6f2ea,
                surfaceContainerLowest: 0xffffff,
                surfaceContainer: 0xdde9e1,
                primaryBrand: 0x1e7d52,
                onPrimary: 0xeffff5,
                secondaryContainer: 0xc9f0dd,
                onSecondaryContainer: 0x1f5b41,
                tertiaryContainer: 0xdef3c7,
                onTertiaryContainer: 0x35541f,
                onSurface: 0x23302a,
                onSurfaceVariant: 0x4f6258,
                outlineVariant: 0x9fb5a8
            )
        case .oceanBreeze:
            return ThemePalette(
                background: 0xeef6fb,
                surfaceContainerLow: 0xe3f0f8,
                surfaceContainerLowest: 0xffffff,
                surfaceContainer: 0xd8e8f3,
                primaryBrand: 0x0b5f93,
                onPrimary: 0xeaf6ff,
                secondaryContainer: 0xcbe7fb,
                onSecondaryContainer: 0x234a67,
                tertiaryContainer: 0xd7e3ff,
                onTertiaryContainer: 0x303f68,
                onSurface: 0x1d2d39,
                onSurfaceVariant: 0x4f6170,
                outlineVariant: 0x99aebb
            )
        case .light:
        return ThemePalette(
            background: 0xF9FAEF,           // md_theme_background
            surfaceContainerLow: 0xF3F4E9,  // md_theme_surfaceContainerLow
            surfaceContainerLowest: 0xFFFFFF, // md_theme_surfaceContainerLowest
            surfaceContainer: 0xEEEFE3,     // md_theme_surfaceContainer
            primaryBrand: 0x4C662B,         // md_theme_primary
            onPrimary: 0xFFFFFF,            // md_theme_onPrimary
            secondaryContainer: 0xDCE7C8,   // md_theme_secondaryContainer
            onSecondaryContainer: 0x404A33, // md_theme_onSecondaryContainer
            tertiaryContainer: 0xBCECE7,    // md_theme_tertiaryContainer
            onTertiaryContainer: 0x1F4E4B,  // md_theme_onTertiaryContainer
            onSurface: 0x1A1C16,            // md_theme_onSurface
            onSurfaceVariant: 0x44483D,     // md_theme_onSurfaceVariant
            outlineVariant: 0xC5C8BA        // md_theme_outlineVariant
        )
        case .dark:
        return ThemePalette(
            background: 0x12140E,           // md_theme_background
            surfaceContainerLow: 0x1A1C16,  // md_theme_surfaceContainerLow
            surfaceContainerLowest: 0x0C0F09, // md_theme_surfaceContainerLowest
            surfaceContainer: 0x1E201A,     // md_theme_surfaceContainer
            primaryBrand: 0xB1D18A,         // md_theme_primary
            onPrimary: 0x1F3701,            // md_theme_onPrimary
            secondaryContainer: 0x404A33,   // md_theme_secondaryContainer
            onSecondaryContainer: 0xDCE7C8, // md_theme_onSecondaryContainer
            tertiaryContainer: 0x1F4E4B,    // md_theme_tertiaryContainer
            onTertiaryContainer: 0xBCECE7,  // md_theme_onTertiaryContainer
            onSurface: 0xE2E3D8,            // md_theme_onSurface
            onSurfaceVariant: 0xC5C8BA,     // md_theme_onSurfaceVariant
            outlineVariant: 0x44483D        // md_theme_outlineVariant
        )
        case .wodlot:
        return ThemePalette(
            // Backgrounds - Elegant & Aged
            background: 0xF5F0E8,           // Warm parchment/aged paper
            surfaceContainerLow: 0xEDE6DB,    // Soft cream
            surfaceContainerLowest: 0xFFFFFF, // Pure white
            surfaceContainer: 0xE3D9CA,       // Warm limestone
            
            // Primary Brand - Deep Wine
            primaryBrand: 0x8B2C2D,           // Rich burgundy (red wine)
            onPrimary: 0xFFFFFF,              // White text
            
            // Secondary - Olive & Herb
            secondaryContainer: 0x8A9A7B,     // Sage green (olive leaves)
            onSecondaryContainer: 0x2D3A24,   // Deep forest green
            
            // Tertiary - Oak & Leather
            tertiaryContainer: 0xB87B4A,       // Warm oak/leather
            onTertiaryContainer: 0x4A2A14,    // Dark espresso
            
            // Text & Surface
            onSurface: 0x2B2825,              // Dark charcoal
            onSurfaceVariant: 0x6B6257,       // Warm gray-brown
            outlineVariant: 0xC9C0B3           // Soft beige border
        )
        }
        
    }
}

enum UIChromeStore {
    static let hideBottomNavKey = "cookloop.hideBottomNav"
}

extension Color {
    static var appBackground: Color { Color(hex: ThemeStore.palette.background) }
    static var background: Color { Color(hex: ThemeStore.palette.background) }
    static var surfaceContainerLow: Color { Color(hex: ThemeStore.palette.surfaceContainerLow) }
    static var surfaceContainerLowest: Color { Color(hex: ThemeStore.palette.surfaceContainerLowest) }
    static var surfaceContainer: Color { Color(hex: ThemeStore.palette.surfaceContainer) }
    static var primaryBrand: Color { Color(hex: ThemeStore.palette.primaryBrand) }
    static var onPrimary: Color { Color(hex: ThemeStore.palette.onPrimary) }
    static var secondaryContainer: Color { Color(hex: ThemeStore.palette.secondaryContainer) }
    static var onSecondaryContainer: Color { Color(hex: ThemeStore.palette.onSecondaryContainer) }
    static var tertiaryContainer: Color { Color(hex: ThemeStore.palette.tertiaryContainer) }
    static var onTertiaryContainer: Color { Color(hex: ThemeStore.palette.onTertiaryContainer) }
    static var onSurface: Color { Color(hex: ThemeStore.palette.onSurface) }
    static var onSurfaceVariant: Color { Color(hex: ThemeStore.palette.onSurfaceVariant) }
    static var outlineVariant: Color { Color(hex: ThemeStore.palette.outlineVariant) }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double((hex >> 0) & 0xff) / 255,
            opacity: alpha
        )
    }
}


struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var bookmarkViewModel = BookmarkViewModel()
    @AppStorage(ThemeStore.selectedThemeKey) private var selectedThemeKey = AppTheme.warmClassic.rawValue
    @AppStorage(UIChromeStore.hideBottomNavKey) private var hideBottomNav = false
    @State private var selectedTab: AppTab = .discover
    @State private var tabRootRefreshID = UUID()

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.background.ignoresSafeArea()
            mainContent
                .id("\(tabRootRefreshID.uuidString)-\(selectedThemeKey)")

            if !hideBottomNav {
                bottomNavBar
                fab
            }
        }
        .onAppear {
            if authViewModel.currentUser == nil {
                authViewModel.fetchUser()
            }
            bookmarkViewModel.startListening()
            GamificationService.shared.runWeeklyCalculation()
        }
        .environmentObject(bookmarkViewModel)
    }

    @ViewBuilder
    var mainContent: some View {
        switch selectedTab {
        case .discover:
            DiscoverView()
        case .feed:
            FeedView()
                .environmentObject(bookmarkViewModel)
        case .upload:
            UploadView()
        case .profile:
            Group {
                if let currentUserId = authViewModel.userSession?.uid ?? authViewModel.currentUser?.id,
                   !currentUserId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    NavigationView {
                        ProfileView(userId: currentUserId)
                    }
                } else {
                    Text("Loading profile...")
                        .foregroundColor(.onSurfaceVariant)
                }
            }
            .environmentObject(bookmarkViewModel)
        case .activity:
            ActivityView()
        }
    }

    var bottomNavBar: some View {
        HStack {
            navItem(icon: "flame.fill", label: "Feed", tab: .feed)
            Spacer()
            navItem(icon: "safari.fill", label: "Discover", tab: .discover)
            Spacer()
            navItem(icon: "bell.fill", label: "Activity", tab: .activity)
            Spacer()
            navItem(icon: "plus.circle.fill", label: "Upload", tab: .upload)
            Spacer()
            navItem(icon: "person.fill", label: "Profile", tab: .profile)
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 30)
        .background(
            Color.background
                .clipShape(RoundedRectangle(cornerRadius: 48))
                .shadow(color: .onSurface.opacity(0.06), radius: 40, x: 0, y: -4)
        )
        .ignoresSafeArea()
    }

    fileprivate func navItem(icon: String, label: String, tab: AppTab) -> some View {
        let isActive = selectedTab == tab
        return Button(action: {
            selectedTab = tab
            tabRootRefreshID = UUID()
        }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(.system(size: 9, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .allowsTightening(true)
            }
            .foregroundColor(isActive ? .primaryBrand : .outlineVariant)
            .padding(.horizontal, isActive ? 16 : 10)
            .padding(.vertical, isActive ? 12 : 10)
            .background(isActive ? Color.secondaryContainer : Color.clear)
            .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }

    var fab: some View {
        Button(action: {
            selectedTab = .upload
        }) {
            Circle()
                .fill(Color.primaryBrand)
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "flame.fill")
                        .foregroundColor(.onPrimary)
                        .font(.system(size: 24))
                )
                .shadow(color: Color.primaryBrand.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 120)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
    }
}

struct AppTopBar: View {
    var title: String = "CookLoop"
    var subtitle: String? = nil
    var showsBackButton: Bool = false
    var trailingSystemIcon: String? = "magnifyingglass"
    var onBackTap: (() -> Void)? = nil
    var onTrailingTap: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                if showsBackButton {
                    Button(action: { onBackTap?() }) {
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

                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primaryBrand)

                Spacer()

                if let trailingSystemIcon = trailingSystemIcon {
                    Button(action: { onTrailingTap?() }) {
                        Image(systemName: trailingSystemIcon)
                            .foregroundColor(.primaryBrand)
                            .font(.system(size: 20))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            if let subtitle = subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.onSurfaceVariant)
            }
        }
    }
}

struct SearchRecipesSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText: String = ""
    @State private var isLoading = false
    @State private var pendingLoads = 0
    @State private var errorMessage = ""
    @State private var allRecipes: [CookLoop.Recipe] = []
    @State private var allUsers: [SearchUser] = []
    @State private var selectedRecipe: CookLoop.Recipe?
    @State private var showRecipeDetail = false
    @State private var selectedUserId: String = ""
    @State private var showUserProfile = false

    private let db = Firestore.firestore()

    private var filteredRecipes: [CookLoop.Recipe] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else {
            return Array(allRecipes.prefix(20))
        }

        return allRecipes.filter { recipe in
            let inTitle = recipe.title.lowercased().contains(query)
            let inTags = recipe.tags.joined(separator: " ").lowercased().contains(query)
            let inIngredients = recipe.ingredients.joined(separator: " ").lowercased().contains(query)
            return inTitle || inTags || inIngredients
        }
    }

    private var filteredUsers: [SearchUser] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else {
            return Array(allUsers.prefix(12))
        }

        return allUsers.filter { user in
            let name = user.name.lowercased()
            let bio = user.bio.lowercased()
            return name.contains(query) || bio.contains(query)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 14) {
                    AppTopBar(
                        subtitle: "Search recipes across CookLoop",
                        showsBackButton: true,
                        trailingSystemIcon: nil,
                        onBackTap: { presentationMode.wrappedValue.dismiss() }
                    )

                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.primaryBrand)
                        TextField("Search by title, ingredient, or tag...", text: $searchText)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .foregroundColor(.onSurface)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.surfaceContainerLowest)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .primaryBrand))
                            Spacer()
                        }
                        .padding(.top, 20)
                    } else if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    } else if filteredRecipes.isEmpty && filteredUsers.isEmpty {
                        Text("No users or recipes matched your search.")
                            .foregroundColor(.onSurfaceVariant)
                            .padding(.top, 10)
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 14) {
                                if !filteredUsers.isEmpty {
                                    Text("Users")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(.onSurface)

                                    LazyVStack(spacing: 10) {
                                        ForEach(filteredUsers) { user in
                                            Button(action: {
                                                selectedUserId = user.id
                                                showUserProfile = true
                                            }) {
                                                HStack(spacing: 10) {
                                                    if let profileImage = user.profileImage,
                                                       !profileImage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                                        RemoteImageView(urlString: profileImage)
                                                            .frame(width: 56, height: 56)
                                                            .clipShape(Circle())
                                                    } else {
                                                        Circle()
                                                            .fill(Color.surfaceContainer)
                                                            .frame(width: 56, height: 56)
                                                            .overlay(
                                                                Image(systemName: "person.fill")
                                                                    .foregroundColor(.primaryBrand)
                                                            )
                                                    }

                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text(user.name)
                                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                                            .foregroundColor(.onSurface)
                                                            .lineLimit(1)

                                                        if !user.bio.isEmpty {
                                                            Text(user.bio)
                                                                .font(.caption)
                                                                .foregroundColor(.onSurfaceVariant)
                                                                .lineLimit(1)
                                                        }
                                                    }

                                                    Spacer()
                                                }
                                                .padding(10)
                                                .background(Color.surfaceContainerLowest)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.outlineVariant.opacity(0.25), lineWidth: 1)
                                                )
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }

                                if !filteredRecipes.isEmpty {
                                    Text("Recipes")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(.onSurface)

                                    LazyVStack(spacing: 10) {
                                        ForEach(filteredRecipes) { recipe in
                                            Button(action: {
                                                selectedRecipe = recipe
                                                showRecipeDetail = true
                                            }) {
                                                HStack(spacing: 10) {
                                                    if !recipe.imageUrl.isEmpty {
                                                        RemoteImageView(urlString: recipe.imageUrl)
                                                            .frame(width: 56, height: 56)
                                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                                    } else {
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .fill(Color.surfaceContainer)
                                                            .frame(width: 56, height: 56)
                                                            .overlay(
                                                                Image(systemName: "flame.fill")
                                                                    .foregroundColor(.primaryBrand)
                                                            )
                                                    }

                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text(recipe.title)
                                                            .font(.system(size: 15, weight: .bold, design: .rounded))
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
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.outlineVariant.opacity(0.25), lineWidth: 1)
                                                )
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                            }
                        }
                    }

                    NavigationLink(
                        destination: Group {
                            if let selectedRecipe = selectedRecipe {
                                RecipeDetailView(recipe: selectedRecipe)
                            } else {
                                Text("CookLoop.Recipe unavailable")
                            }
                        },
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
                .padding(.horizontal, 16)
                .padding(.top, 0)
                .padding(.bottom, 18)
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            loadRecipes()
            loadUsers()
        }
    }

    private func loadRecipes() {
        beginLoading()
        errorMessage = ""

        db.collection("recipes")
            .order(by: "createdAt", descending: true)
            .limit(to: 150)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    self.endLoading()

                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        return
                    }

                    self.allRecipes = snapshot?.documents.compactMap { doc in
                        RecipeViewModel.parseRecipe(id: doc.documentID, data: doc.data())
                    } ?? []
                }
            }
    }

    private func loadUsers() {
        beginLoading()

        db.collection("users")
            .limit(to: 150)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    self.endLoading()

                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        return
                    }

                    self.allUsers = snapshot?.documents.map { doc in
                        let data = doc.data()
                        let name = data["name"] as? String ?? "Cook"
                        let bio = data["bio"] as? String ?? ""
                        let profileImage = data["profileImage"] as? String
                        return SearchUser(
                            id: doc.documentID,
                            name: name,
                            bio: bio,
                            profileImage: profileImage
                        )
                    } ?? []
                }
            }
    }

    private func beginLoading() {
        pendingLoads += 1
        isLoading = true
    }

    private func endLoading() {
        pendingLoads = max(0, pendingLoads - 1)
        isLoading = pendingLoads > 0
    }
}

private struct SearchUser: Identifiable {
    let id: String
    let name: String
    let bio: String
    let profileImage: String?
}

private enum AppTab {
    case feed
    case discover
    case activity
    case upload
    case profile
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthViewModel())
    }
}
