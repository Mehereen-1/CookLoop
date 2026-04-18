//
//  AuthService.swift
//  CookLoop
//
//  Created by Ayesha Meherin on 27/3/26.
//

import Foundation
import FirebaseFirestore

enum CookLoopLevel: String {
	case beginnerCook = "Beginner Cook"
	case homeChef = "Home Chef"
	case proChef = "Pro Chef"
	case masterChef = "Master Chef"
}

enum CookLoopBadge: String {
	case topContributor = "Top Contributor"
	case trendingChef = "Trending Chef"
	case communityHelper = "Community Helper"
	case recipeCreator = "Recipe Creator"
	case lovedChef = "Loved Chef"
}

final class GamificationService {
	static let shared = GamificationService()

	private let db = Firestore.firestore()
	private let calendar = Calendar(identifier: .iso8601)

	private init() {}

	func awardRecipePosted(userId: String) {
		award(
			userId: userId,
			points: 10,
			eventType: "recipe_posted",
			engagementDelta: 10,
			weeklyMetric: "recipesPosted",
			totalMetric: "totalRecipesPosted",
			immediateBadges: [.recipeCreator]
		)
	}

	func awardLikeReceived(userId: String) {
		award(
			userId: userId,
			points: 2,
			eventType: "like_received",
			engagementDelta: 2,
			weeklyMetric: "likesReceived",
			totalMetric: "totalLikesReceived"
		)
	}

	func awardComment(userId: String) {
		award(
			userId: userId,
			points: 1,
			eventType: "comment_added",
			engagementDelta: 1,
			weeklyMetric: "commentsCount",
			totalMetric: "totalComments"
		)
	}

	func awardBookmark(userId: String) {
		award(
			userId: userId,
			points: 1,
			eventType: "bookmark_added",
			engagementDelta: 1,
			weeklyMetric: "bookmarksCount",
			totalMetric: "totalBookmarks"
		)
	}

	func runWeeklyCalculation(weekDate: Date = Date()) {
		let weekId = weekKey(for: weekDate)

		db.collection("weeklyStats")
			.document(weekId)
			.collection("users")
			.getDocuments { snapshot, _ in
				let docs = snapshot?.documents ?? []
				guard !docs.isEmpty else { return }

				let ranked = docs.map { doc -> (userId: String, engagement: Int, consistency: Int) in
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

				let topCount = max(1, Int(ceil(Double(ranked.count) * 0.10)))
				let winners = Array(ranked.prefix(topCount)).map { $0.userId }

				for userId in winners {
					self.addBadges(to: userId, badges: [.topContributor])
				}

				for item in ranked {
					self.evaluateWeeklyBadges(userId: item.userId, weekId: weekId)
				}
			}
	}

	private func award(
		userId: String,
		points: Int,
		eventType: String,
		engagementDelta: Int,
		weeklyMetric: String,
		totalMetric: String,
		immediateBadges: [CookLoopBadge] = []
	) {
		let cleanedUserId = userId.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !cleanedUserId.isEmpty else { return }

		let userRef = db.collection("users").document(cleanedUserId)
		let now = Date()
		let dayId = dayKey(for: now)
		let weekId = weekKey(for: now)

		db.runTransaction({ transaction, _ in
			let snapshot: DocumentSnapshot
			do {
				snapshot = try transaction.getDocument(userRef)
			} catch {
				return nil
			}

			let data = snapshot.data() ?? [:]
			let currentXP = Self.parseInt(data["xp"]) ?? 0
			let updatedXP = currentXP + points

			let currentLevelRaw = (data["level"] as? String ?? "")
			let computedLevel = self.resolveLevel(forXP: updatedXP).rawValue
			let resolvedLevel = currentLevelRaw.isEmpty ? computedLevel : computedLevel

			var payload: [String: Any] = [
				"xp": updatedXP,
				"level": resolvedLevel,
				totalMetric: FieldValue.increment(Int64(1)),
				"lastGamificationEventAt": Timestamp(date: now)
			]

			var existingBadges = data["badges"] as? [String] ?? []
			let newBadgeNames = immediateBadges.map { $0.rawValue }
			existingBadges.append(contentsOf: newBadgeNames)
			existingBadges = Array(Set(existingBadges)).sorted()
			payload["badges"] = existingBadges

			transaction.setData(payload, forDocument: userRef, merge: true)

			let eventRef = userRef.collection("gamificationEvents").document()
			transaction.setData([
				"type": eventType,
				"points": points,
				"engagementDelta": engagementDelta,
				"day": dayId,
				"week": weekId,
				"createdAt": Timestamp(date: now)
			], forDocument: eventRef)

			let weeklyRef = self.db.collection("weeklyStats")
				.document(weekId)
				.collection("users")
				.document(cleanedUserId)

			let weeklyData: [String: Any]
			if let snapshot = try? transaction.getDocument(weeklyRef) {
				weeklyData = snapshot.data() ?? [:]
			} else {
				weeklyData = [:]
			}
			var dayFlags = weeklyData["dayFlags"] as? [String: Bool] ?? [:]
			let hadActivityToday = dayFlags[dayId] == true
			dayFlags[dayId] = true

			let existingConsistency = Self.parseInt(weeklyData["consistency"]) ?? 0
			let existingActiveDays = Self.parseInt(weeklyData["activeDays"]) ?? 0
			let nextActiveDays = hadActivityToday ? existingActiveDays : min(7, existingActiveDays + 1)
			let nextConsistency = hadActivityToday ? existingConsistency : min(7, existingConsistency + 1)

			var weeklyPayload: [String: Any] = [
				"userId": cleanedUserId,
				"updatedAt": Timestamp(date: now),
				"engagementScore": FieldValue.increment(Int64(engagementDelta)),
				weeklyMetric: FieldValue.increment(Int64(1)),
				"activeDays": nextActiveDays,
				"consistency": nextConsistency,
				"dayFlags": dayFlags
			]

			weeklyPayload["weekId"] = weekId

			transaction.setData(weeklyPayload, forDocument: weeklyRef, merge: true)
			return nil
		}) { _, _ in
			self.evaluateWeeklyBadges(userId: cleanedUserId, weekId: weekId)
			self.runWeeklyCalculation(weekDate: now)
		}
	}

	private func evaluateWeeklyBadges(userId: String, weekId: String) {
		let weeklyRef = db.collection("weeklyStats")
			.document(weekId)
			.collection("users")
			.document(userId)

		let userRef = db.collection("users").document(userId)

		weeklyRef.getDocument { weeklySnapshot, _ in
			let weekly = weeklySnapshot?.data() ?? [:]
			let likesReceived = Self.parseInt(weekly["likesReceived"]) ?? 0
			let commentsCount = Self.parseInt(weekly["commentsCount"]) ?? 0

			var badgesToGrant: [CookLoopBadge] = []
			if likesReceived >= 12 {
				badgesToGrant.append(.trendingChef)
			}
			if commentsCount >= 8 {
				badgesToGrant.append(.communityHelper)
			}

			userRef.getDocument { userSnapshot, _ in
				let userData = userSnapshot?.data() ?? [:]
				let totalLikesReceived = Self.parseInt(userData["totalLikesReceived"]) ?? 0
				if totalLikesReceived >= 30 {
					badgesToGrant.append(.lovedChef)
				}

				self.addBadges(to: userId, badges: badgesToGrant)
			}
		}
	}

	private func addBadges(to userId: String, badges: [CookLoopBadge]) {
		guard !badges.isEmpty else { return }

		let badgeNames = badges.map { $0.rawValue }
		let userRef = db.collection("users").document(userId)

		userRef.updateData([
			"badges": FieldValue.arrayUnion(badgeNames)
		])
	}

	private func resolveLevel(forXP xp: Int) -> CookLoopLevel {
		if xp >= 400 {
			return .masterChef
		}

		if xp >= 150 {
			return .proChef
		}

		if xp >= 50 {
			return .homeChef
		}

		return .beginnerCook
	}

	private func weekKey(for date: Date) -> String {
		let weekOfYear = calendar.component(.weekOfYear, from: date)
		let yearForWeek = calendar.component(.yearForWeekOfYear, from: date)
		return String(format: "%04d-W%02d", yearForWeek, weekOfYear)
	}

	private func dayKey(for date: Date) -> String {
		let formatter = DateFormatter()
		formatter.calendar = calendar
		formatter.dateFormat = "yyyy-MM-dd"
		return formatter.string(from: date)
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
