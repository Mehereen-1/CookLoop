//
//  RecipeCardView.swift
//  CookLoop
//
//  Created by GitHub Copilot on 7/4/26.
//

import SwiftUI

struct RecipeCardView: View {
    let recipe: Recipe
    let username: String
    let isLiked: Bool
    let onLike: () -> Void
    var isBookmarked: Bool = false
    var onBookmarkTap: (() -> Void)? = nil
    var onUserTap: (() -> Void)? = nil
    var onCardTap: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
                    mediaAndTitle
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                mediaAndTitle
            }

            HStack(spacing: 12) {
                Button(action: onLike) {
                    HStack(spacing: 6) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .gray)
                        Text("\(recipe.likes)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if let onBookmarkTap = onBookmarkTap {
                    Button(action: {
                        onBookmarkTap()
                    }) {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .foregroundColor(isBookmarked ? .orange : .gray)
                    }
                }
            }
        }
        .padding(10)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(14)
    }

    private var userRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "person.crop.circle.fill")
                .foregroundColor(.orange)
            Text(username)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
    }

    private var mediaAndTitle: some View {
        VStack(alignment: .leading, spacing: 8) {
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
                        .fill(Color.orange.opacity(0.12))
                }
            }
            .frame(height: 150)
            .clipped()
            .cornerRadius(12)

            Text(recipe.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
                .foregroundColor(.primary)
        }
    }
}