//
//  AdminPanelView.swift
//  CookLoop
//
//  Created by Ayesha Meherin on 27/3/26.
//

import SwiftUI

struct AdminPanelView: View {
	@EnvironmentObject private var authViewModel: AuthViewModel
	@StateObject private var viewModel = AdminViewModel()
	@State private var showLogoutConfirmation = false

	var body: some View {
		NavigationView {
			ZStack {
				Color.appBackground.ignoresSafeArea()

				ScrollView(showsIndicators: false) {
					VStack(alignment: .leading, spacing: 16) {
						AppTopBar(
							title: "Admin Panel",
							subtitle: "Monitor users, recipes, and reports",
							trailingSystemIcon: "rectangle.portrait.and.arrow.right",
							onTrailingTap: { authViewModel.signOut() }
						)

						statsGrid
						quickActions

						if !viewModel.errorMessage.isEmpty {
							Text(viewModel.errorMessage)
								.font(.footnote)
								.foregroundColor(.red)
						}
					}
					.padding(16)
				}
			}
			.navigationBarHidden(true)
		}
		.navigationViewStyle(StackNavigationViewStyle())
		.onAppear {
			viewModel.startListening()
		}
		.onDisappear {
			viewModel.stopListening()
		}
	}

	private var statsGrid: some View {
		LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
			StatCard(title: "Total Users", value: "\(viewModel.totalUsers)", icon: "person.3.fill")
			StatCard(title: "Total Recipes", value: "\(viewModel.totalRecipes)", icon: "book.fill")
			StatCard(title: "Total Reports", value: "\(viewModel.totalReports)", icon: "exclamationmark.bubble.fill")
			StatCard(title: "Pending", value: "\(viewModel.pendingReports)", icon: "clock.fill")
		}
	}

	private var quickActions: some View {
		VStack(spacing: 10) {
			NavigationLink(destination: AdminUsersView(viewModel: viewModel)) {
				actionRow(title: "Manage Users", subtitle: "Ban or unban users", icon: "person.crop.circle.badge.exclamationmark")
			}

			NavigationLink(destination: AdminRecipesView(viewModel: viewModel)) {
				actionRow(title: "Manage Recipes", subtitle: "Delete inappropriate recipes", icon: "trash.square")
			}

			NavigationLink(destination: AdminReportsView(viewModel: viewModel)) {
				actionRow(title: "Reports", subtitle: "Review and resolve reports", icon: "flag.fill")
			}

			Button(action: {
				showLogoutConfirmation = true
			}) {
				logoutRow
			}
			.buttonStyle(PlainButtonStyle())
		}
		.alert(isPresented: $showLogoutConfirmation) {
			Alert(
				title: Text("Logout?"),
				message: Text("You will need to sign in again to access the Admin Panel."),
				primaryButton: .destructive(Text("Logout")) {
					authViewModel.signOut()
				},
				secondaryButton: .cancel()
			)
		}
	}

	private var logoutRow: some View {
		HStack(spacing: 12) {
			Image(systemName: "rectangle.portrait.and.arrow.right")
				.font(.system(size: 20, weight: .semibold))
				.foregroundColor(.red)
				.frame(width: 36, height: 36)
				.background(Color.red.opacity(0.12))
				.clipShape(RoundedRectangle(cornerRadius: 10))

			VStack(alignment: .leading, spacing: 4) {
				Text("Logout")
					.font(.system(size: 16, weight: .bold, design: .rounded))
					.foregroundColor(.onSurface)

				Text("Sign out from admin account")
					.font(.caption)
					.foregroundColor(.onSurfaceVariant)
			}

			Spacer()
		}
		.padding(12)
		.background(Color.surfaceContainerLowest)
		.clipShape(RoundedRectangle(cornerRadius: 14))
		.overlay(
			RoundedRectangle(cornerRadius: 14)
				.stroke(Color.outlineVariant.opacity(0.26), lineWidth: 1)
		)
	}

	private func actionRow(title: String, subtitle: String, icon: String) -> some View {
		HStack(spacing: 12) {
			Image(systemName: icon)
				.font(.system(size: 20, weight: .semibold))
				.foregroundColor(.primaryBrand)
				.frame(width: 36, height: 36)
				.background(Color.secondaryContainer)
				.clipShape(RoundedRectangle(cornerRadius: 10))

			VStack(alignment: .leading, spacing: 4) {
				Text(title)
					.font(.system(size: 16, weight: .bold, design: .rounded))
					.foregroundColor(.onSurface)

				Text(subtitle)
					.font(.caption)
					.foregroundColor(.onSurfaceVariant)
			}

			Spacer()

			Image(systemName: "chevron.right")
				.font(.system(size: 12, weight: .bold))
				.foregroundColor(.outlineVariant)
		}
		.padding(12)
		.background(Color.surfaceContainerLowest)
		.clipShape(RoundedRectangle(cornerRadius: 14))
		.overlay(
			RoundedRectangle(cornerRadius: 14)
				.stroke(Color.outlineVariant.opacity(0.26), lineWidth: 1)
		)
	}
}

private struct AdminUsersView: View {
	@ObservedObject var viewModel: AdminViewModel
	@State private var searchText = ""
	@State private var selectedUser: AdminUserItem?

	private var filteredUsers: [AdminUserItem] {
		let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
		guard !query.isEmpty else { return viewModel.users }

		return viewModel.users.filter { user in
			user.username.lowercased().contains(query) || user.email.lowercased().contains(query)
		}
	}

	var body: some View {
		ScrollView(showsIndicators: false) {
			VStack(alignment: .leading, spacing: 12) {
				adminSearchField(placeholder: "Search users", text: $searchText)

				ForEach(filteredUsers) { user in
					VStack(alignment: .leading, spacing: 8) {
						HStack {
							Text(user.username)
								.font(.system(size: 16, weight: .bold, design: .rounded))
							Spacer()
							if user.isAdmin {
								Text("Admin")
									.font(.caption2)
									.foregroundColor(.onPrimary)
									.padding(.horizontal, 8)
									.padding(.vertical, 4)
									.background(Color.primaryBrand)
									.clipShape(Capsule())
							}
						}

						Text(user.email)
							.font(.subheadline)
							.foregroundColor(.onSurfaceVariant)

						Text("Recipes: \(user.recipeCount)")
							.font(.caption)
							.foregroundColor(.onSurfaceVariant)

						Button(user.isBanned ? "Unban User" : "Ban User") {
							selectedUser = user
						}
						.font(.system(size: 14, weight: .bold, design: .rounded))
						.foregroundColor(user.isBanned ? .green : .red)
					}
					.padding(12)
					.background(Color.surfaceContainerLowest)
					.clipShape(RoundedRectangle(cornerRadius: 12))
				}
			}
			.padding(16)
		}
		.background(Color.appBackground.ignoresSafeArea())
		.navigationTitle("Manage Users")
		.alert(item: $selectedUser) { user in
			let title = user.isBanned ? "Unban this user?" : "Ban this user?"
			let actionLabel = user.isBanned ? "Unban" : "Ban"

			return Alert(
				title: Text(title),
				message: Text(user.username),
				primaryButton: .destructive(Text(actionLabel)) {
					viewModel.setBanStatus(for: user.id, isBanned: !user.isBanned)
				},
				secondaryButton: .cancel()
			)
		}
	}
}

private struct AdminRecipesView: View {
	@ObservedObject var viewModel: AdminViewModel
	@State private var searchText = ""
	@State private var selectedRecipe: AdminRecipeItem?

	private var filteredRecipes: [AdminRecipeItem] {
		let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
		guard !query.isEmpty else { return viewModel.recipes }

		return viewModel.recipes.filter { recipe in
			recipe.title.lowercased().contains(query) || recipe.creatorName.lowercased().contains(query)
		}
	}

	var body: some View {
		ScrollView(showsIndicators: false) {
			VStack(alignment: .leading, spacing: 12) {
				adminSearchField(placeholder: "Search recipes", text: $searchText)

				ForEach(filteredRecipes) { recipe in
					VStack(alignment: .leading, spacing: 8) {
						Text(recipe.title)
							.font(.system(size: 16, weight: .bold, design: .rounded))
							.foregroundColor(.onSurface)

						Text("By: \(recipe.creatorName)")
							.font(.subheadline)
							.foregroundColor(.onSurfaceVariant)

						Text("Likes: \(recipe.likes)")
							.font(.caption)
							.foregroundColor(.onSurfaceVariant)

						Button("Delete Recipe") {
							selectedRecipe = recipe
						}
						.font(.system(size: 14, weight: .bold, design: .rounded))
						.foregroundColor(.red)
					}
					.padding(12)
					.background(Color.surfaceContainerLowest)
					.clipShape(RoundedRectangle(cornerRadius: 12))
				}
			}
			.padding(16)
		}
		.background(Color.appBackground.ignoresSafeArea())
		.navigationTitle("Manage Recipes")
		.alert(item: $selectedRecipe) { recipe in
			Alert(
				title: Text("Delete recipe?"),
				message: Text(recipe.title),
				primaryButton: .destructive(Text("Delete")) {
					viewModel.deleteRecipe(recipeId: recipe.id)
				},
				secondaryButton: .cancel()
			)
		}
	}
}

private struct AdminReportsView: View {
	@ObservedObject var viewModel: AdminViewModel
	@State private var selectedType: String = "all"
	@State private var selectedStatus: String = "pending"
	@State private var selectedReport: AdminReportItem?
	@State private var reportToDeleteContent: AdminReportItem?

	private var filteredReports: [AdminReportItem] {
		viewModel.reports.filter { report in
			let matchesType = selectedType == "all" || report.type.lowercased() == selectedType
			let matchesStatus = selectedStatus == "all" || report.status.lowercased() == selectedStatus
			return matchesType && matchesStatus
		}
	}

	var body: some View {
		ScrollView(showsIndicators: false) {
			VStack(alignment: .leading, spacing: 12) {
				filterBar

				if filteredReports.isEmpty {
					Text("No reports found for this filter.")
						.foregroundColor(.onSurfaceVariant)
						.padding(.top, 12)
				}

				ForEach(filteredReports) { report in
					VStack(alignment: .leading, spacing: 8) {
						HStack {
							Text(report.type.uppercased())
								.font(.caption2)
								.foregroundColor(.onPrimary)
								.padding(.horizontal, 8)
								.padding(.vertical, 4)
								.background(Color.primaryBrand)
								.clipShape(Capsule())

							Text(report.status.capitalized)
								.font(.caption2)
								.foregroundColor(report.status.lowercased() == "resolved" ? .green : .orange)
							Spacer()
						}

						Text(report.reason)
							.font(.system(size: 15, weight: .semibold, design: .rounded))
							.foregroundColor(.onSurface)

						Text("Target: \(report.targetId)")
							.font(.caption)
							.foregroundColor(.onSurfaceVariant)
						Text("Reported by: \(viewModel.displayName(for: report.reportedBy))")
							.font(.caption)
							.foregroundColor(.onSurfaceVariant)

						HStack(spacing: 12) {
							Button("View Content") {
								selectedReport = report
							}
							.font(.caption)

							Button("Delete Content") {
								reportToDeleteContent = report
							}
							.font(.caption)
							.foregroundColor(.red)

							Button("Mark Resolved") {
								viewModel.resolveReport(reportId: report.id)
							}
							.font(.caption)
							.foregroundColor(.primaryBrand)
						}
					}
					.padding(12)
					.background(Color.surfaceContainerLowest)
					.clipShape(RoundedRectangle(cornerRadius: 12))
				}
			}
			.padding(16)
		}
		.background(Color.appBackground.ignoresSafeArea())
		.navigationTitle("Reports")
		.alert(item: $reportToDeleteContent) { report in
			Alert(
				title: Text("Delete reported content?"),
				message: Text("This action cannot be undone."),
				primaryButton: .destructive(Text("Delete")) {
					viewModel.deleteTargetContent(for: report)
				},
				secondaryButton: .cancel()
			)
		}
		.sheet(item: $selectedReport) { report in
			ReportDetailSheet(report: report, viewModel: viewModel)
		}
	}

	private var filterBar: some View {
		HStack(spacing: 10) {
			Menu {
				Button("All") { selectedType = "all" }
				Button("Recipe") { selectedType = "recipe" }
				Button("User") { selectedType = "user" }
				Button("Comment") { selectedType = "comment" }
			} label: {
				Text("Type: \(selectedType.capitalized)")
					.font(.caption)
					.padding(.horizontal, 10)
					.padding(.vertical, 8)
					.background(Color.surfaceContainerLowest)
					.clipShape(Capsule())
			}

			Menu {
				Button("Pending") { selectedStatus = "pending" }
				Button("Resolved") { selectedStatus = "resolved" }
				Button("All") { selectedStatus = "all" }
			} label: {
				Text("Status: \(selectedStatus.capitalized)")
					.font(.caption)
					.padding(.horizontal, 10)
					.padding(.vertical, 8)
					.background(Color.surfaceContainerLowest)
					.clipShape(Capsule())
			}
		}
	}
}

private struct ReportDetailSheet: View {
	let report: AdminReportItem
	@ObservedObject var viewModel: AdminViewModel
	@Environment(\.presentationMode) private var presentationMode

	var body: some View {
		NavigationView {
			VStack(alignment: .leading, spacing: 12) {
				Text("Reason")
					.font(.headline)
				Text(report.reason)
					.foregroundColor(.onSurface)

				Divider()

				Text("Type: \(report.type)")
				Text("Target: \(report.targetId)")
				Text("Reported by: \(viewModel.displayName(for: report.reportedBy))")

				if report.type.lowercased() == "recipe" {
					Text("Recipe title: \(viewModel.recipeTitle(for: report.targetId))")
				}

				Spacer()
			}
			.padding(16)
			.background(Color.appBackground.ignoresSafeArea())
			.navigationBarTitle("Report Detail", displayMode: .inline)
			.navigationBarItems(trailing: Button("Close") {
				presentationMode.wrappedValue.dismiss()
			})
		}
		.navigationViewStyle(StackNavigationViewStyle())
	}
}

private struct StatCard: View {
	let title: String
	let value: String
	let icon: String

	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			Image(systemName: icon)
				.foregroundColor(.primaryBrand)
			Text(value)
				.font(.system(size: 22, weight: .bold, design: .rounded))
				.foregroundColor(.onSurface)
			Text(title)
				.font(.caption)
				.foregroundColor(.onSurfaceVariant)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(12)
		.background(Color.surfaceContainerLowest)
		.clipShape(RoundedRectangle(cornerRadius: 12))
		.overlay(
			RoundedRectangle(cornerRadius: 12)
				.stroke(Color.outlineVariant.opacity(0.26), lineWidth: 1)
		)
	}
}

private func adminSearchField(placeholder: String, text: Binding<String>) -> some View {
	HStack(spacing: 8) {
		Image(systemName: "magnifyingglass")
			.foregroundColor(.primaryBrand)
		TextField(placeholder, text: text)
			.autocapitalization(.none)
			.disableAutocorrection(true)
	}
	.padding(.horizontal, 12)
	.padding(.vertical, 10)
	.background(Color.surfaceContainerLowest)
	.clipShape(RoundedRectangle(cornerRadius: 10))
}

extension AdminUserItem: Equatable {
	static func == (lhs: AdminUserItem, rhs: AdminUserItem) -> Bool {
		lhs.id == rhs.id
	}
}

extension AdminUserItem: Hashable {
	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
}

extension AdminRecipeItem: Equatable {
	static func == (lhs: AdminRecipeItem, rhs: AdminRecipeItem) -> Bool {
		lhs.id == rhs.id
	}
}

extension AdminRecipeItem: Hashable {
	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
}

extension AdminReportItem: Equatable {
	static func == (lhs: AdminReportItem, rhs: AdminReportItem) -> Bool {
		lhs.id == rhs.id
	}
}

extension AdminReportItem: Hashable {
	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
}
