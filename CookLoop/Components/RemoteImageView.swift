//
//  RemoteImageView.swift
//  CookLoop
//
//  Created by GitHub Copilot on 7/4/26.
//

import SwiftUI
import UIKit

final class ImageLoader: ObservableObject {
    @Published var image: UIImage?

    private static let cache = NSCache<NSString, UIImage>()

    func load(from urlString: String) {
        guard !urlString.isEmpty else {
            image = nil
            return
        }

        if let dataURLImage = imageFromDataURL(urlString) {
            image = dataURLImage
            Self.cache.setObject(dataURLImage, forKey: urlString as NSString)
            return
        }

        guard let url = URL(string: urlString) else {
            image = nil
            return
        }

        if let cachedImage = Self.cache.object(forKey: urlString as NSString) {
            image = cachedImage
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let fetchedImage = UIImage(data: data) else { return }

            Self.cache.setObject(fetchedImage, forKey: urlString as NSString)
            DispatchQueue.main.async {
                self.image = fetchedImage
            }
        }.resume()
    }

    private func imageFromDataURL(_ value: String) -> UIImage? {
        guard value.hasPrefix("data:image") else { return nil }
        guard let commaIndex = value.firstIndex(of: ",") else { return nil }

        let base64Part = String(value[value.index(after: commaIndex)...])
        guard let data = Data(base64Encoded: base64Part) else { return nil }
        return UIImage(data: data)
    }
}

struct RemoteImageView: View {
    let urlString: String
    @StateObject private var imageLoader = ImageLoader()

    var body: some View {
        Group {
            if let image = imageLoader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Rectangle()
                        .fill(Color.orange.opacity(0.12))
                    Image(systemName: "flame.fill")
                        .font(.system(size: 28, weight: .regular))
                        .foregroundColor(Color.orange.opacity(0.6))
                }
            }
        }
        .onAppear {
            imageLoader.load(from: urlString)
        }
    }
}