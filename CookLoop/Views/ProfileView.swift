//
//  ProfileView.swift
//  CookLoop
//
//  Created by Ayesha Meherin on 26/3/26.
//

import SwiftUI

struct ProfileView: View {
    let items = ["food1", "food2", "food3", "food4"]

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {

                    VStack {
                        Image("profile")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())

                        Text("Ayesha")
                            .font(.headline)

                        Text("Food lover 🍰")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(items, id: \.self) { item in
                            Image(item)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 100)
                                .clipped()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Profile")
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
