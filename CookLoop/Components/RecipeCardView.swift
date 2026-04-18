//
//  RecipeCardView.swift
//  CookLoop
//
//  Created by GitHub Copilot on 7/4/26.
//

import SwiftUI

struct RecipeCardView: View {
    let recipe: CookLoop.Recipe
    let username: String
    let isLiked: Bool
    let onLike: () -> Void
    var isBookmarked: Bool = false
    var onBookmarkTap: (() -> Void)? = nil
    var onRepostTap: (() -> Void)? = nil
    var onUserTap: (() -> Void)? = nil
    var onCardTap: (() -> Void)? = nil
    var liveBadgeText: String? = nil
    var repostedByText: String? = nil
    var quoteText: String? = nil
    var postDateText: String? = nil

    var body: some View {
        ZStack(alignment: .topLeading) {
            cardBody

            if let liveBadgeText = liveBadgeText {
                Text(liveBadgeText)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(.onPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.primaryBrand)
                    .clipShape(Capsule())
                    .padding(.leading, 18)
                    .padding(.top, 14)
            }
        }
    }

    private var cardBody: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack(alignment: .topLeading) {
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
                .frame(height: 300)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 34))

                HStack {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.surfaceContainerLowest.opacity(0.75))
                    Spacer()
                }
                .padding(16)
            }

            if let onUserTap = onUserTap {
                Button(action: {
                    onUserTap()
                }) {
                    userRow
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                userRow
            }

            if let onCardTap = onCardTap {
                Button(action: {
                    onCardTap()
                }) {
                    titleRow
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                titleRow
            }

            if let quoteText = quoteText, !quoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("\"\(quoteText)\"")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.onSurfaceVariant)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.surfaceContainerLow)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            if let postDateText = postDateText {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.onPrimary)

                    Text(postDateText)
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(.onPrimary)
                        .lineLimit(1)

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.primaryBrand, Color(hex: 0xe06057)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Divider()
                .overlay(Color.outlineVariant.opacity(0.45))

            HStack {
                HStack(spacing: 18) {
                    Button(action: onLike) {
                        HStack(spacing: 6) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(isLiked ? Color(hex: 0xe06057) : .onSurfaceVariant)
                            Text("\(recipe.likes)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.onSurfaceVariant)
                        }
                    }

                    if let onBookmarkTap = onBookmarkTap {
                        Button(action: {
                            onBookmarkTap()
                        }) {
                            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(isBookmarked ? Color(hex: 0xbf6b11) : .onSurfaceVariant)
                        }
                    }

                    if let onRepostTap = onRepostTap {
                        Button(action: {
                            onRepostTap()
                        }) {
                            Image(systemName: "arrow.2.squarepath")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.onSurfaceVariant)
                        }
                    }
                }

                Spacer()

                if let onCardTap = onCardTap {
                    Button(action: {
                        onCardTap()
                    }) {
                        HStack(spacing: 6) {
                            Text("Get Recipe")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(.onPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.primaryBrand)
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(14)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 34))
        .overlay(
            RoundedRectangle(cornerRadius: 34)
                .stroke(Color.surfaceContainer.opacity(0.6), lineWidth: 3)
        )
        .overlay(
            ZStack(alignment: .topTrailing) {
                Color.surfaceContainerLowest.opacity(0.7)
                    .frame(width: 50, height: 18)
                    .rotationEffect(.degrees(12))
                    .offset(x: -16, y: -8)
            }
        )
        .shadow(color: .onSurface.opacity(0.08), radius: 18, x: 0, y: 12)
    }

    private var userRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let repostedByText = repostedByText {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.2.squarepath")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.onSurfaceVariant)
                    Text(repostedByText)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.onSurfaceVariant)
                        .lineLimit(1)
                }
            }

            HStack(spacing: 6) {
                Image(systemName: "person.crop.circle.fill")
                    .foregroundColor(.primaryBrand)
                Text(username)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.onSurface)
                    .lineLimit(1)
            }
        }
    }

    private var titleRow: some View {
        Text(recipe.title)
            .font(.system(size: 32, weight: .black, design: .rounded))
            .foregroundColor(.onSurface)
            .lineSpacing(2)
            .lineLimit(3)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}