//
//  AdminViewModel.swift
//  CookLoop
//
//  Created by Ayesha Meherin on 27/3/26.
//

import Foundation
import FirebaseFirestore

struct AdminUserItem: Identifiable {
	let id: String
	let username: String
	let email: String
	let recipeCount: Int
	let isBanned: Bool
	let isAdmin: Bool
}

struct AdminRecipeItem: Identifiable {
	let id: String
	let title: String
	let creatorId: String
	let creatorName: String
	let likes: Int
	let createdAt: Date
}

struct AdminReportItem: Identifiable {
	let id: String
	let type: String
	let targetId: String
	let reason: String
	let reportedBy: String
	let createdAt: Date
	let status: String
}

final class AdminViewModel: ObservableObject {
	@Published var users: [AdminUserItem] = []
	@Published var recipes: [AdminRecipeItem] = []
	@Published var reports: [AdminReportItem] = []
	@Published var errorMessage: String = ""

	private let db = Firestore.firestore()
	private var usersListener: ListenerRegistration?
	private var recipesListener: ListenerRegistration?
	private var reportsListener: ListenerRegistration?

	private var rawUsersById: [String: [String: Any]] = [:]
	private var rawRecipesById: [String: [String: Any]] = [:]

	deinit {
		stopListening()
	}

	var totalUsers: Int {
		users.count
	}

	var totalRecipes: Int {
		recipes.count
	}

	var totalReports: Int {
		reports.count
	}

	var pendingReports: Int {
		reports.filter { $0.status.lowercased() == "pending" }.count
	}

	func startListening() {
		attachUsersListener()
		attachRecipesListener()
		attachReportsListener()
	}

	func stopListening() {
		usersListener?.remove()
		usersListener = nil

		recipesListener?.remove()
		recipesListener = nil

		reportsListener?.remove()
		reportsListener = nil
	}

	func setBanStatus(for userId: String, isBanned: Bool) {
		db.collection("users").document(userId).updateData([
			"isBanned": isBanned
		]) { error in
			if let error = error {
				DispatchQueue.main.async {
					self.errorMessage = error.localizedDescription
				}
			}
		}
	}

	func deleteRecipe(recipeId: String) {
		db.collection("recipes").document(recipeId).delete { error in
			if let error = error {
				DispatchQueue.main.async {
					self.errorMessage = error.localizedDescription
				}
			}
		}
	}

	func resolveReport(reportId: String) {
		db.collection("reports").document(reportId).updateData([
			"status": "resolved"
		]) { error in
			if let error = error {
				DispatchQueue.main.async {
					self.errorMessage = error.localizedDescription
				}
			}
		}
	}

	func deleteTargetContent(for report: AdminReportItem) {
		let normalizedType = report.type.lowercased()

		if normalizedType == "recipe" {
			deleteRecipe(recipeId: report.targetId)
			return
		}

		if normalizedType == "user" {
			setBanStatus(for: report.targetId, isBanned: true)
			return
		}

		if normalizedType == "comment" {
			deleteComment(targetId: report.targetId)
		}
	}

	func displayName(for userId: String) -> String {
		if let data = rawUsersById[userId] {
			let name = data["name"] as? String ?? ""
			if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
				return name
			}
		}

		return userId
	}

	func recipeTitle(for recipeId: String) -> String {
		if let data = rawRecipesById[recipeId] {
			let title = data["title"] as? String ?? ""
			if !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
				return title
			}
		}

		return recipeId
	}

	private func attachUsersListener() {
		usersListener?.remove()

		usersListener = db.collection("users").addSnapshotListener { snapshot, error in
			if let error = error {
				DispatchQueue.main.async {
					self.errorMessage = error.localizedDescription
				}
				return
			}

			let docs = snapshot?.documents ?? []
			var mappedUsersById: [String: [String: Any]] = [:]
			for doc in docs {
				mappedUsersById[doc.documentID] = doc.data()
			}

			DispatchQueue.main.async {
				self.rawUsersById = mappedUsersById
				self.rebuildUsers()
				self.rebuildRecipes()
				self.rebuildReports()
			}
		}
	}

	private func attachRecipesListener() {
		recipesListener?.remove()

		recipesListener = db.collection("recipes")
			.order(by: "createdAt", descending: true)
			.addSnapshotListener { snapshot, error in
				if let error = error {
					DispatchQueue.main.async {
						self.errorMessage = error.localizedDescription
					}
					return
				}

				let docs = snapshot?.documents ?? []
				var mappedRecipesById: [String: [String: Any]] = [:]
				for doc in docs {
					mappedRecipesById[doc.documentID] = doc.data()
				}

				DispatchQueue.main.async {
					self.rawRecipesById = mappedRecipesById
					self.rebuildUsers()
					self.rebuildRecipes()
				}
			}
	}

	private func attachReportsListener() {
		reportsListener?.remove()

		reportsListener = db.collection("reports")
			.order(by: "createdAt", descending: true)
			.addSnapshotListener { snapshot, error in
				if let error = error {
					DispatchQueue.main.async {
						self.errorMessage = error.localizedDescription
					}
					return
				}

				let docs = snapshot?.documents ?? []
				let mappedReports: [AdminReportItem] = docs.map { doc in
					let data = doc.data()
					return AdminReportItem(
						id: doc.documentID,
						type: data["type"] as? String ?? "unknown",
						targetId: data["targetId"] as? String ?? "",
						reason: data["reason"] as? String ?? "No reason provided",
						reportedBy: data["reportedBy"] as? String ?? "",
						createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
						status: data["status"] as? String ?? "pending"
					)
				}

				DispatchQueue.main.async {
					self.reports = mappedReports
				}
			}
	}

	private func rebuildUsers() {
		var recipeCounts: [String: Int] = [:]
		for (_, recipeData) in rawRecipesById {
			let uid = recipeData["userId"] as? String ?? ""
			if uid.isEmpty { continue }
			recipeCounts[uid, default: 0] += 1
		}

		let mapped: [AdminUserItem] = rawUsersById.map { (userId, data) in
			AdminUserItem(
				id: userId,
				username: data["name"] as? String ?? "Cook",
				email: data["email"] as? String ?? "",
				recipeCount: recipeCounts[userId] ?? 0,
				isBanned: data["isBanned"] as? Bool ?? false,
				isAdmin: data["isAdmin"] as? Bool ?? false
			)
		}
		.sorted { $0.username.lowercased() < $1.username.lowercased() }

		users = mapped
	}

	private func rebuildRecipes() {
		let mapped: [AdminRecipeItem] = rawRecipesById.map { (recipeId, data) in
			let creatorId = data["userId"] as? String ?? ""
			let creatorName = rawUsersById[creatorId]?["name"] as? String ?? "Cook"

			return AdminRecipeItem(
				id: recipeId,
				title: data["title"] as? String ?? "Untitled Recipe",
				creatorId: creatorId,
				creatorName: creatorName,
				likes: Self.parseInt(data["likes"]) ?? 0,
				createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
			)
		}
		.sorted { $0.createdAt > $1.createdAt }

		recipes = mapped
	}

	private func rebuildReports() {
		reports = reports.sorted { $0.createdAt > $1.createdAt }
	}

	private func deleteComment(targetId: String) {
		let chunks = targetId.split(separator: "/")
		if chunks.count >= 2 {
			let recipeId = String(chunks[0])
			let commentId = String(chunks[1])

			db.collection("recipes")
				.document(recipeId)
				.collection("comments")
				.document(commentId)
				.delete { error in
					if let error = error {
						DispatchQueue.main.async {
							self.errorMessage = error.localizedDescription
						}
					}
				}
			return
		}

		db.collectionGroup("comments")
			.whereField("id", isEqualTo: targetId)
			.getDocuments { snapshot, error in
				if let error = error {
					DispatchQueue.main.async {
						self.errorMessage = error.localizedDescription
					}
					return
				}

				for doc in snapshot?.documents ?? [] {
					doc.reference.delete()
				}
			}
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
