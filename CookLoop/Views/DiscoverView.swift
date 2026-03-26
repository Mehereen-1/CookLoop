//
//  DiscoverView.swift
//  CookLoop
//
//  Created by Ayesha Meherin on 26/3/26.
//

import SwiftUI

struct DiscoverView: View {
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    let items = ["food1", "food2", "food3", "food4", "food5"]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(items, id: \.self) { item in
                        Image(item)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 150)
                            .clipped()
                            .cornerRadius(15)
                    }
                }
                .padding()
            }
            .navigationTitle("Discover")
        }
    }
}

struct DiscoverView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverView()
    }
}
