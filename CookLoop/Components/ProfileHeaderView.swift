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

    var body: some View {
        VStack(spacing: 10) {
            Circle()
                .fill(Color.orange.opacity(0.18))
                .frame(width: 84, height: 84)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.orange)
                )

            Text(name)
                .font(.title3)
                .fontWeight(.bold)

            Text(bio.isEmpty ? "Food lover at CookLoop" : bio)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
}