//
//  ProfileHeaderView.swift
//  CookLoop
//
//  Created by GitHub Copilot on 7/4/26.
//

import SwiftUI

struct ProfileHeaderView: View {
    let name: String
    let bio: String
    let recipeCount: Int
    let savedCount: Int
    let showingSaved: Bool

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.secondaryContainer, Color.tertiaryContainer]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 110)

                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.surfaceContainerLowest.opacity(0.9))
                        .frame(width: 64, height: 64)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.primaryBrand)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(name)
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundColor(.onSurface)
                            .lineLimit(1)

                        Text(showingSaved ? "Saved Collection" : "Recipe Collection")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.onSurfaceVariant)
                    }

                    Spacer()
                }
                .padding(.horizontal, 14)
            }

            Text(bio.isEmpty ? "Food lover at CookLoop" : bio)
                .font(.subheadline)
                .foregroundColor(.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)

            HStack(spacing: 10) {
                statBadge(title: "Recipes", value: recipeCount)
                statBadge(title: "Saved", value: savedCount)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 2)
    }

    private func statBadge(title: String, value: Int) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.headline)
                .foregroundColor(.onSurface)
            Text(title)
                .font(.caption2)
                .foregroundColor(.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.outlineVariant.opacity(0.35), lineWidth: 1)
        )
    }
}