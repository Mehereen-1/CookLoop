//
//  ActivityView.swift
//  CookLoop
//
//  Created by GitHub Copilot on 14/4/26.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ActivityView: View {
    @StateObject private var viewModel = ActivityViewModel()
    @StateObject private var leaderboardViewModel = LeaderboardViewModel()
    @State private var selectedMode: ActivityMode = .notifications
    @State private var showSearch = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        AppTopBar(subtitle: selectedMode == .notifications ? "Your latest notifications" : "Weekly leaderboard", onTrailingTap: { showSearch = true })

                        Picker("View", selection: $selectedMode) {
                            Text("Notifications").tag(ActivityMode.notifications)
                            Text("Leaderboard").tag(ActivityMode.leaderboard)
                        }
                        .pickerStyle(SegmentedPickerStyle())

                        contentView
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 0)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            viewModel.startListening()
            leaderboardViewModel.loadWeeklyLeaderboard()
        }
        .onDisappear {
            viewModel.stopListening()
        }
        .onChange(of: selectedMode) { newValue in
            if newValue == .leaderboard {
                leaderboardViewModel.loadWeeklyLeaderboard()
            }
        }
        .sheet(isPresented: $showSearch) {
            SearchRecipesSheet()
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch selectedMode {
        case .notifications:
            notificationsView
        case .leaderboard:
            leaderboardView
        }
    }

    @ViewBuilder
    private var notificationsView: some View {
        if viewModel.notifications.isEmpty {
            Text("No activity yet.")
                .foregroundColor(.onSurfaceVariant)
        } else {
            ForEach(viewModel.notifications) { activity in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: activity.type.iconName)
                        .foregroundColor(.primaryBrand)
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(activity.actorName) \(activity.type.title)")
                            .font(.subheadline)
                            .foregroundColor(.onSurface)

                        if let text = activity.text, !text.isEmpty {
                            Text(text)
                                .font(.caption)
                                .foregroundColor(.onSurfaceVariant)
                                .lineLimit(2)
                        }
                        Text(relativeTime(activity.createdAt))
                            .font(.caption2)
                            .foregroundColor(.onSurfaceVariant)
                    }

                    Spacer()
                }
                .padding(.vertical, 4)
                .background(Color.surfaceContainerLowest)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    @ViewBuilder
    private var leaderboardView: some View {
        if leaderboardViewModel.isLoading {
            HStack {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .primaryBrand))
                Spacer()
            }
            .padding(.top, 8)
        } else if !leaderboardViewModel.errorMessage.isEmpty {
            Text(leaderboardViewModel.errorMessage)
                .foregroundColor(.red)
        } else if leaderboardViewModel.entries.isEmpty {
            Text("No leaderboard data for this week yet. Post and engage to rank!")
                .foregroundColor(.onSurfaceVariant)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                if let rank = leaderboardViewModel.currentUserRank {
                    Text("Your rank this week: #\(rank)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.primaryBrand)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.surfaceContainerLowest)
                        .clipShape(Capsule())
                }

                ForEach(Array(leaderboardViewModel.entries.enumerated()), id: \.element.id) { index, entry in
                    HStack(spacing: 12) {
                        Text(rankEmoji(for: index + 1))
                            .font(.system(size: 22))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.name)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(.onSurface)
                                .lineLimit(1)

                            Text("Engagement: \(entry.engagementScore) · Consistency: \(entry.consistency)/7")
                                .font(.caption)
                                .foregroundColor(.onSurfaceVariant)
                        }

                        Spacer()

                        Text("#\(index + 1)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.primaryBrand)
                    }
                    .padding(12)
                    .background(Color.surfaceContainerLowest)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.outlineVariant.opacity(0.28), lineWidth: 1)
                    )
                }
            }
        }
    }

    private func rankEmoji(for rank: Int) -> String {
        switch rank {
        case 1:
            return "🥇"
        case 2:
            return "🥈"
        case 3:
            return "🥉"
        default:
            return "🍳"
        }
    }

    private func relativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct ActivityView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityView()
    }
}

private enum ActivityMode {
    case notifications
    case leaderboard
}

private struct LeaderboardEntry: Identifiable {
    let id: String
    let name: String
    let engagementScore: Int
    let consistency: Int
}

private final class LeaderboardViewModel: ObservableObject {
    @Published var entries: [LeaderboardEntry] = []
    @Published var currentUserRank: Int?
    @Published var isLoading = false
    @Published var errorMessage = ""

    private let db = Firestore.firestore()
    private let calendar = Calendar(identifier: .iso8601)

    func loadWeeklyLeaderboard() {
        isLoading = true
        errorMessage = ""

        let weekId = currentWeekKey()
        let leaderboardRef = db.collection("weeklyStats")
            .document(weekId)
            .collection("users")

        leaderboardRef.getDocuments { snapshot, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
                return
            }

            let docs = snapshot?.documents ?? []
            let rankingSeed: [(userId: String, engagement: Int, consistency: Int)] = docs.map { doc in
                let data = doc.data()
                let userId = data["userId"] as? String ?? doc.documentID
                let engagement = Self.parseInt(data["engagementScore"]) ?? 0
                let consistency = Self.parseInt(data["consistency"]) ?? 0
                return (userId: userId, engagement: engagement, consistency: consistency)
            }
            .sorted {
                if $0.engagement == $1.engagement {
                    return $0.consistency > $1.consistency
                }
                return $0.engagement > $1.engagement
            }

            let orderedUserIds = rankingSeed.map { $0.userId }
            let scoresByUser = Dictionary(uniqueKeysWithValues: rankingSeed.map { ($0.userId, ($0.engagement, $0.consistency)) })

            if orderedUserIds.isEmpty {
                DispatchQueue.main.async {
                    self.entries = []
                    self.currentUserRank = nil
                    self.isLoading = false
                }
                return
            }

            self.loadUserNames(for: orderedUserIds) { namesById in
                let mapped: [LeaderboardEntry] = orderedUserIds.compactMap { uid in
                    guard let score = scoresByUser[uid] else { return nil }
                    return LeaderboardEntry(
                        id: uid,
                        name: namesById[uid] ?? "Cook",
                        engagementScore: score.0,
                        consistency: score.1
                    )
                }

                let trimmed = Array(mapped.prefix(25))
                let currentUid = Auth.auth().currentUser?.uid
                let rank = currentUid.flatMap { uid in
                    orderedUserIds.firstIndex(of: uid).map { $0 + 1 }
                }

                DispatchQueue.main.async {
                    self.entries = trimmed
                    self.currentUserRank = rank
                    self.isLoading = false
                }
            }
        }
    }

    private func loadUserNames(for userIds: [String], completion: @escaping ([String: String]) -> Void) {
        let chunks = chunked(userIds, size: 10)
        var namesById: [String: String] = [:]
        let group = DispatchGroup()

        for chunk in chunks where !chunk.isEmpty {
            group.enter()
            db.collection("users")
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments { snapshot, _ in
                    defer { group.leave() }

                    for doc in snapshot?.documents ?? [] {
                        let name = doc.data()["name"] as? String ?? "Cook"
                        namesById[doc.documentID] = name
                    }
                }
        }

        group.notify(queue: .main) {
            completion(namesById)
        }
    }

    private func currentWeekKey() -> String {
        let now = Date()
        let weekOfYear = calendar.component(.weekOfYear, from: now)
        let yearForWeek = calendar.component(.yearForWeekOfYear, from: now)
        return String(format: "%04d-W%02d", yearForWeek, weekOfYear)
    }

    private func chunked(_ ids: [String], size: Int) -> [[String]] {
        guard size > 0 else { return [] }
        var chunks: [[String]] = []
        var index = 0

        while index < ids.count {
            let end = Swift.min(index + size, ids.count)
            chunks.append(Array(ids[index..<end]))
            index += size
        }

        return chunks
    }

    private static func parseInt(_ value: Any?) -> Int? {
        if let intValue = value as? Int {
            return intValue
        }

        if let int64Value = value as? Int64 {
            return Int(int64Value)
        }

        if let doubleValue = value as? Double {
            return Int(doubleValue)
        }

        return nil
    }
}
