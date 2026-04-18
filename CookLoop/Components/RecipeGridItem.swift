//
//  RecipeGridItem.swift
//  CookLoop
//
//  Created by Ayesha Meherin on 27/3/26.
//

import Foundation
import SwiftUI

struct RecipeGridItem: View {
    var recipe: CookLoop.Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Group {
                if !recipe.imageUrl.isEmpty {
                    RemoteImageView(urlString: recipe.imageUrl)
                } else if let imageData = recipe.legacyImageData,
                          let data = Data(base64Encoded: imageData),
                          let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
            }
            .frame(height: 110)
            .clipped()
            .cornerRadius(10)

            Text(recipe.title)
                .font(.caption)
                .lineLimit(1)
                .foregroundColor(.primary)
        }
    }
}
