//
//  ContentView.swift
//  CookLoop
//
//  Created by Ayesha Meherin on 26/3/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var bookmarkViewModel = BookmarkViewModel()

    var body: some View {
        TabView {
            FeedView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Feed")
                }

            UploadView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Upload")
                }

            Group {
                if let currentUserId = authViewModel.currentUser?.id {
                    ProfileView(userId: currentUserId)
                } else {
                    Text("Loading profile...")
                }
            }
            .tabItem {
                Image(systemName: "person.fill")
                Text("Profile")
            }
        }
        .accentColor(.orange)
        .environmentObject(bookmarkViewModel)
        .onAppear {
            if authViewModel.currentUser == nil {
                authViewModel.fetchUser()
            }

            bookmarkViewModel.startListening()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
