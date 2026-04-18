//
//  RecipeViewModel.swift
//  CookLoop
//
//  Created by Ayesha Meherin on 27/3/26.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth

class RecipeViewModel: ObservableObject {

    enum FeedMode {
        case global
        case following
    }

    struct FeedItem: Identifiable {
        let id: String
        var recipe: CookLoop.Recipe
        let createdAt: Date
        let repostedByUserId: String?
        let quoteComment: String?

        var isRepost: Bool {
            repostedByUserId != nil
        }
    }

    private struct RepostRecord {
        let id: String
        let userId: String
        let originalRecipeId: String
        let comment: String?
        let createdAt: Date
    }

    @Published var isUploading = false
    @Published var errorMessage = ""
    @Published var recipes: [CookLoop.Recipe] = []
    @Published var feedItems: [FeedItem] = []
    @Published var likesByRecipeId: [String: Bool] = [:]
    @Published var newlyAddedRecipeIDs: Set<String> = []
    @Published var hasNewCommentActivityByRecipeId: [String: Bool] = [:]
    
    private let db = Firestore.firestore()
    private var recipesListener: ListenerRegistration?
    private var repostsListener: ListenerRegistration?
    private var followingListener: ListenerRegistration?
    private var followingRecipeListeners: [ListenerRegistration] = []
    private var followingRepostListeners: [ListenerRegistration] = []
    private var followingRecipeChunkSnapshots: [Int: [QueryDocumentSnapshot]] = [:]
    private var followingRepostChunkSnapshots: [Int: [QueryDocumentSnapshot]] = [:]
    private var commentListenersByRecipeId: [String: ListenerRegistration] = [:]

    private var latestRecipeDocuments: [QueryDocumentSnapshot] = []
    private var latestRepostDocuments: [QueryDocumentSnapshot] = []
    private var recipeCacheById: [String: CookLoop.Recipe] = [:]
    private var requestedMissingRecipeIDs: Set<String> = []

    private let pageLimit = 20
    private(set) var lastDocument: DocumentSnapshot?
    private var hasLoadedInitialSnapshot = false
    private(set) var currentFeedMode: FeedMode = .global

    deinit {
        stopListeningToRecipes()
    }
    
    func uploadRecipe(
        title: String,
        ingredients: [String],
        steps: [String],
        imageUrl: String,
        cookingTimeMinutes: Int,
        difficulty: String,
        tags: [String],
        completion: ((Bool) -> Void)? = nil
    ) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanedTitle.isEmpty else {
            errorMessage = "Please enter a recipe title."
            completion?(false)
            return
        }
        
        isUploading = true
        errorMessage = ""
        let recipeId = UUID().uuidString
        
        let data: [String: Any] = [
            "id": recipeId,
            "userId": uid,
            "title": cleanedTitle,
            "imageUrl": imageUrl.trimmingCharacters(in: .whitespacesAndNewlines),
            "ingredients": ingredients,
            "steps": steps,
            "cookingTimeMinutes": max(5, cookingTimeMinutes),
            "difficulty": difficulty.trimmingCharacters(in: .whitespacesAndNewlines),
            "tags": tags,
            "likes": 0,
            "createdAt": Timestamp(date: Date())
        ]
        
        db.collection("recipes").document(recipeId).setData(data) { error in
            DispatchQueue.main.async {
                self.isUploading = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    completion?(false)
                    return
                }

                GamificationService.shared.awardRecipePosted(userId: uid)
                self.fetchRecipes()
                completion?(true)
            }
        }
    }

    func fetchRecipes() {
        db.collection("recipes")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        return
                    }

                    let fetchedRecipes: [CookLoop.Recipe] = snapshot?.documents.compactMap { doc in
                        Self.parseRecipe(id: doc.documentID, data: doc.data())
                    } ?? []

                    self.recipes = fetchedRecipes
                    self.fetchLikeStateForCurrentUser()
                }
            }
    }

    func startListeningToFeed(mode: FeedMode) {
        currentFeedMode = mode

        switch mode {
        case .global:
            startListeningToGlobalFeed()
        case .following:
            startListeningToFollowingFeed()
        }
    }

    func startListeningToRecipes() {
        startListeningToFeed(mode: .global)
    }

    func startListeningToGlobalFeed() {
        stopListeningToRecipes()
        errorMessage = ""
        resetFeedStateForModeSwitch()
        latestRecipeDocuments = []
        latestRepostDocuments = []

        let recipesQuery = db.collection("recipes")
            .order(by: "createdAt", descending: true)
            .limit(to: pageLimit)

        recipesListener = recipesQuery.addSnapshotListener { snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                guard let snapshot = snapshot else { return }
                self.lastDocument = snapshot.documents.last
                self.latestRecipeDocuments = snapshot.documents
                self.rebuildFeedFromLatestDocuments()
            }
        }

        let repostsQuery = db.collection("reposts")
            .order(by: "createdAt", descending: true)
            .limit(to: pageLimit)

        repostsListener = repostsQuery.addSnapshotListener { snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                guard let snapshot = snapshot else { return }
                self.latestRepostDocuments = snapshot.documents
                self.rebuildFeedFromLatestDocuments()
            }
        }
    }

    func startListeningToFollowingFeed() {
        stopListeningToRecipes()
        errorMessage = ""
        resetFeedStateForModeSwitch()

        guard let uid = Auth.auth().currentUser?.uid else {
            startListeningToGlobalFeed()
            return
        }

        followingListener = db.collection("users")
            .document(uid)
            .collection("following")
            .addSnapshotListener { snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        self.attachGlobalFeedListenersForFollowingFallback()
                        return
                    }

                    let followedIDs = snapshot?.documents.map { $0.documentID } ?? []
                    self.configureFollowingFeedListeners(followedUserIDs: followedIDs)
                }
            }
    }

    func stopListeningToRecipes() {
        recipesListener?.remove()
        recipesListener = nil
        repostsListener?.remove()
        repostsListener = nil
        followingListener?.remove()
        followingListener = nil

        for listener in followingRecipeListeners {
            listener.remove()
        }
        followingRecipeListeners.removeAll()

        for listener in followingRepostListeners {
            listener.remove()
        }
        followingRepostListeners.removeAll()

        followingRecipeChunkSnapshots.removeAll()
        followingRepostChunkSnapshots.removeAll()
        latestRecipeDocuments = []
        latestRepostDocuments = []

        hasLoadedInitialSnapshot = false
        lastDocument = nil

        for listener in commentListenersByRecipeId.values {
            listener.remove()
        }
        commentListenersByRecipeId.removeAll()
    }

    func markRecipeAsSeen(_ recipeId: String) {
        newlyAddedRecipeIDs.remove(recipeId)
        hasNewCommentActivityByRecipeId[recipeId] = false
    }

    func toggleLike(for recipe: CookLoop.Recipe) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let recipeRef = db.collection("recipes").document(recipe.id)
        let likeRef = recipeRef.collection("likes").document(uid)

        likeRef.getDocument { snapshot, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
                return
            }

            let alreadyLiked = snapshot?.exists ?? false
            let batch = self.db.batch()

            if alreadyLiked {
                batch.deleteDocument(likeRef)
                batch.updateData(["likes": FieldValue.increment(Int64(-1))], forDocument: recipeRef)
            } else {
                batch.setData(["createdAt": Timestamp(date: Date())], forDocument: likeRef)
                batch.updateData(["likes": FieldValue.increment(Int64(1))], forDocument: recipeRef)
            }

            batch.commit { batchError in
                DispatchQueue.main.async {
                    if let batchError = batchError {
                        self.errorMessage = batchError.localizedDescription
                        return
                    }

                    self.likesByRecipeId[recipe.id] = !alreadyLiked
                    if let index = self.recipes.firstIndex(where: { $0.id == recipe.id }) {
                        let delta = alreadyLiked ? -1 : 1
                        self.recipes[index].likes = max(0, self.recipes[index].likes + delta)
                    }

                    for index in self.feedItems.indices where self.feedItems[index].recipe.id == recipe.id {
                        let delta = alreadyLiked ? -1 : 1
                        self.feedItems[index].recipe.likes = max(0, self.feedItems[index].recipe.likes + delta)
                    }

                    if !alreadyLiked {
                        if recipe.userId != uid {
                            GamificationService.shared.awardLikeReceived(userId: recipe.userId)
                        }

                        self.sendNotification(
                            to: recipe.userId,
                            type: .like,
                            recipeId: recipe.id,
                            text: nil
                        )
                    }
                }
            }
        }
    }

    func createRepost(for recipe: CookLoop.Recipe, comment: String?, completion: ((Bool) -> Void)? = nil) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion?(false)
            return
        }

        let repostRef = db.collection("reposts").document()
        let trimmedComment = (comment ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        var payload: [String: Any] = [
            "id": repostRef.documentID,
            "userId": uid,
            "originalRecipeId": recipe.id,
            "createdAt": Timestamp(date: Date())
        ]

        if !trimmedComment.isEmpty {
            payload["comment"] = trimmedComment
        }

        repostRef.setData(payload) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    completion?(false)
                    return
                }

                self.sendNotification(
                    to: recipe.userId,
                    type: .repost,
                    recipeId: recipe.id,
                    text: trimmedComment
                )

                completion?(true)
            }
        }
    }

    private func sendNotification(to recipientUserId: String, type: ActivityType, recipeId: String?, text: String?) {
        guard let actorUserId = Auth.auth().currentUser?.uid else { return }

        fetchCurrentUserName(userId: actorUserId) { actorName in
            NotificationService.shared.send(
                to: recipientUserId,
                actorUserId: actorUserId,
                actorName: actorName,
                type: type,
                recipeId: recipeId,
                text: text
            )
        }
    }

    private func fetchCurrentUserName(userId: String, completion: @escaping (String) -> Void) {
        db.collection("users").document(userId).getDocument { snapshot, _ in
            let fetched = snapshot?.data()?["name"] as? String
            let normalized = fetched?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            completion(normalized.isEmpty ? "Cook" : normalized)
        }
    }

    private func fetchLikeStateForCurrentUser() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        for recipe in recipes {
            db.collection("recipes")
                .document(recipe.id)
                .collection("likes")
                .document(uid)
                .getDocument { snapshot, _ in
                    DispatchQueue.main.async {
                        self.likesByRecipeId[recipe.id] = snapshot?.exists ?? false
                    }
                }
        }
    }

    private func syncCommentActivityListeners(for recipes: [CookLoop.Recipe]) {
        let recipeIDs = Set(recipes.map { $0.id })

        for (recipeId, listener) in commentListenersByRecipeId where !recipeIDs.contains(recipeId) {
            listener.remove()
            commentListenersByRecipeId.removeValue(forKey: recipeId)
            hasNewCommentActivityByRecipeId.removeValue(forKey: recipeId)
        }

        for recipe in recipes where commentListenersByRecipeId[recipe.id] == nil {
            var hasSeenFirstSnapshot = false

            let listener = db.collection("recipes")
                .document(recipe.id)
                .collection("comments")
                .order(by: "createdAt", descending: true)
                .limit(to: 1)
                .addSnapshotListener { snapshot, error in
                    DispatchQueue.main.async {
                        if error != nil { return }
                        guard let snapshot = snapshot else { return }

                        defer { hasSeenFirstSnapshot = true }
                        if !hasSeenFirstSnapshot { return }

                        let hasNewComment = snapshot.documentChanges.contains { $0.type == .added }
                        if hasNewComment {
                            self.hasNewCommentActivityByRecipeId[recipe.id] = true
                        }
                    }
                }

            commentListenersByRecipeId[recipe.id] = listener
        }
    }

    private func configureFollowingFeedListeners(followedUserIDs: [String]) {
        for listener in followingRecipeListeners {
            listener.remove()
        }
        followingRecipeListeners.removeAll()

        for listener in followingRepostListeners {
            listener.remove()
        }
        followingRepostListeners.removeAll()

        followingRecipeChunkSnapshots.removeAll()
        followingRepostChunkSnapshots.removeAll()
        latestRecipeDocuments = []
        latestRepostDocuments = []
        resetFeedStateForModeSwitch()

        if followedUserIDs.isEmpty {
            attachGlobalFeedListenersForFollowingFallback()
            return
        }

        let chunks = chunked(userIDs: followedUserIDs, size: 10)

        for (index, chunk) in chunks.enumerated() {
            let recipeQuery = db.collection("recipes")
                .whereField("userId", in: chunk)
                .limit(to: pageLimit)

            let recipeListener = recipeQuery.addSnapshotListener { snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        return
                    }

                    guard let snapshot = snapshot else { return }
                    self.followingRecipeChunkSnapshots[index] = snapshot.documents
                    self.rebuildFollowingFeedFromChunks()
                }
            }

            followingRecipeListeners.append(recipeListener)

            let repostQuery = db.collection("reposts")
                .whereField("userId", in: chunk)
                .limit(to: pageLimit)

            let repostListener = repostQuery.addSnapshotListener { snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        return
                    }

                    guard let snapshot = snapshot else { return }
                    self.followingRepostChunkSnapshots[index] = snapshot.documents
                    self.rebuildFollowingFeedFromChunks()
                }
            }

            followingRepostListeners.append(repostListener)
        }
    }

    private func attachGlobalFeedListenersForFollowingFallback() {
        recipesListener?.remove()
        recipesListener = nil
        repostsListener?.remove()
        repostsListener = nil
        hasLoadedInitialSnapshot = false
        latestRecipeDocuments = []
        latestRepostDocuments = []

        let recipeQuery = db.collection("recipes")
            .order(by: "createdAt", descending: true)
            .limit(to: pageLimit)

        recipesListener = recipeQuery.addSnapshotListener { snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                guard let snapshot = snapshot else { return }
                self.lastDocument = snapshot.documents.last
                self.latestRecipeDocuments = snapshot.documents
                self.rebuildFeedFromLatestDocuments()
            }
        }

        let repostQuery = db.collection("reposts")
            .order(by: "createdAt", descending: true)
            .limit(to: pageLimit)

        repostsListener = repostQuery.addSnapshotListener { snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                guard let snapshot = snapshot else { return }
                self.latestRepostDocuments = snapshot.documents
                self.rebuildFeedFromLatestDocuments()
            }
        }
    }

    private func rebuildFollowingFeedFromChunks() {
        var byID: [String: QueryDocumentSnapshot] = [:]

        for documents in followingRecipeChunkSnapshots.values {
            for doc in documents {
                if let existing = byID[doc.documentID] {
                    let existingDate = Self.createdAt(from: existing.data())
                    let incomingDate = Self.createdAt(from: doc.data())
                    if incomingDate > existingDate {
                        byID[doc.documentID] = doc
                    }
                } else {
                    byID[doc.documentID] = doc
                }
            }
        }

        let sortedDocuments = byID.values.sorted {
            Self.createdAt(from: $0.data()) > Self.createdAt(from: $1.data())
        }

        var repostByID: [String: QueryDocumentSnapshot] = [:]
        for documents in followingRepostChunkSnapshots.values {
            for doc in documents {
                repostByID[doc.documentID] = doc
            }
        }

        let sortedReposts = repostByID.values.sorted {
            Self.createdAt(from: $0.data()) > Self.createdAt(from: $1.data())
        }

        let limitedDocuments = Array(sortedDocuments.prefix(pageLimit))
        lastDocument = limitedDocuments.last
        latestRecipeDocuments = limitedDocuments
        latestRepostDocuments = Array(sortedReposts.prefix(pageLimit))
        rebuildFeedFromLatestDocuments()
    }

    private func rebuildFeedFromLatestDocuments() {
        let mappedRecipes: [CookLoop.Recipe] = latestRecipeDocuments.compactMap { doc in
            Self.parseRecipe(id: doc.documentID, data: doc.data())
        }

        for recipe in mappedRecipes {
            recipeCacheById[recipe.id] = recipe
        }

        let repostRecords: [RepostRecord] = latestRepostDocuments.compactMap { doc in
            Self.parseRepost(id: doc.documentID, data: doc.data())
        }

        let missingRecipeIDs = Set(repostRecords.map { $0.originalRecipeId })
            .subtracting(Set(recipeCacheById.keys))
        fetchMissingRecipesIfNeeded(missingRecipeIDs)

        var merged: [FeedItem] = mappedRecipes.map { recipe in
            FeedItem(
                id: "recipe-\(recipe.id)",
                recipe: recipe,
                createdAt: recipe.createdAt,
                repostedByUserId: nil,
                quoteComment: nil
            )
        }

        for repost in repostRecords {
            guard let recipe = recipeCacheById[repost.originalRecipeId] else { continue }

            merged.append(
                FeedItem(
                    id: "repost-\(repost.id)",
                    recipe: recipe,
                    createdAt: repost.createdAt,
                    repostedByUserId: repost.userId,
                    quoteComment: repost.comment
                    )
            )
        }

        let sorted = merged.sorted { $0.createdAt > $1.createdAt }
        applyMergedFeedItems(Array(sorted.prefix(pageLimit)))
    }

    private func applyMergedFeedItems(_ items: [FeedItem]) {
        let oldIDs = Set(feedItems.map { $0.id })
        let newIDs = Set(items.map { $0.id })

        if hasLoadedInitialSnapshot {
            let addedFeedItemIDs = newIDs.subtracting(oldIDs)
            for feedItem in items where addedFeedItemIDs.contains(feedItem.id) {
                newlyAddedRecipeIDs.insert(feedItem.recipe.id)
            }
        }

        feedItems = items

        var seenRecipeIDs: Set<String> = []
        let uniqueRecipes = items.compactMap { item -> CookLoop.Recipe? in
            if seenRecipeIDs.contains(item.recipe.id) { return nil }
            seenRecipeIDs.insert(item.recipe.id)
            return item.recipe
        }

        recipes = uniqueRecipes
        fetchLikeStateForCurrentUser()
        syncCommentActivityListeners(for: uniqueRecipes)
        hasLoadedInitialSnapshot = true
    }

    private func fetchMissingRecipesIfNeeded(_ recipeIDs: Set<String>) {
        let unresolved = recipeIDs.subtracting(requestedMissingRecipeIDs)
        guard !unresolved.isEmpty else { return }

        requestedMissingRecipeIDs.formUnion(unresolved)
        let chunks = Array(unresolved).chunked(into: 10)

        for chunk in chunks where !chunk.isEmpty {
            db.collection("recipes")
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments { snapshot, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self.errorMessage = error.localizedDescription
                            return
                        }

                        let fetchedRecipes = snapshot?.documents.compactMap { doc in
                            Self.parseRecipe(id: doc.documentID, data: doc.data())
                        } ?? []

                        for recipe in fetchedRecipes {
                            self.recipeCacheById[recipe.id] = recipe
                        }

                        self.rebuildFeedFromLatestDocuments()
                    }
                }
        }
    }

    private func resetFeedStateForModeSwitch() {
        hasLoadedInitialSnapshot = false
        lastDocument = nil
        newlyAddedRecipeIDs.removeAll()
        hasNewCommentActivityByRecipeId.removeAll()
        feedItems = []
        recipeCacheById.removeAll()
        requestedMissingRecipeIDs.removeAll()
    }

    private func chunked(userIDs: [String], size: Int) -> [[String]] {
        guard size > 0 else { return [userIDs] }
        var chunks: [[String]] = []
        var index = 0

        while index < userIDs.count {
            let end = min(index + size, userIDs.count)
            chunks.append(Array(userIDs[index..<end]))
            index = end
        }

        return chunks
    }

    private static func createdAt(from data: [String: Any]) -> Date {
        let createdAtTimestamp = data["createdAt"] as? Timestamp
        let legacyTimestamp = data["timestamp"] as? Timestamp
        return createdAtTimestamp?.dateValue() ?? legacyTimestamp?.dateValue() ?? Date.distantPast
    }

    private static func parseRepost(id: String, data: [String: Any]) -> RepostRecord? {
        guard let userId = data["userId"] as? String,
              let originalRecipeId = data["originalRecipeId"] as? String else {
            return nil
        }

        let createdAt = createdAt(from: data)
        let comment = data["comment"] as? String

        return RepostRecord(
            id: id,
            userId: userId,
            originalRecipeId: originalRecipeId,
            comment: comment,
            createdAt: createdAt
        )
    }

    static func parseRecipe(id: String, data: [String: Any]) -> CookLoop.Recipe? {
        let createdAt = createdAt(from: data)
        let likesValue = data["likes"]
        let likes = (likesValue as? Int) ?? Int((likesValue as? Int64) ?? 0)
        let cookingTimeRaw = data["cookingTimeMinutes"]
        let cookingTimeMinutes = (cookingTimeRaw as? Int)
            ?? Int((cookingTimeRaw as? Int64) ?? 0)
        let difficulty = (data["difficulty"] as? String ?? "Intermediate")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let tags = data["tags"] as? [String] ?? []

        return CookLoop.Recipe(
            id: id,
            userId: data["userId"] as? String ?? "",
            title: data["title"] as? String ?? "Untitled CookLoop.Recipe",
            imageUrl: data["imageUrl"] as? String ?? "",
            legacyImageData: data["imageData"] as? String,
            ingredients: data["ingredients"] as? [String] ?? [],
            steps: data["steps"] as? [String] ?? [],
            likes: likes,
            createdAt: createdAt,
            cookingTimeMinutes: max(5, cookingTimeMinutes),
            difficulty: difficulty.isEmpty ? "Intermediate" : difficulty,
            tags: tags
        )
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [] }
        var chunks: [[Element]] = []
        var index = 0

        while index < count {
            let end = Swift.min(index + size, count)
            chunks.append(Array(self[index..<end]))
            index += size
        }

        return chunks
    }
}
