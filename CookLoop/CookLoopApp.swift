//
//  CookLoopApp.swift
//  CookLoop
//
//  Created by Ayesha Meherin on 26/3/26.
//

import SwiftUI

@main
struct CookLoopApp: App {
    @StateObject var viewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            if viewModel.userSession != nil {
                Group {
                    if let currentUser = viewModel.currentUser {
                        if currentUser.isAdmin {
                            AdminPanelView()
                                .environmentObject(viewModel)
                        } else {
                            ContentView()
                                .environmentObject(viewModel)
                        }
                    } else {
                        ZStack {
                            Color.appBackground.ignoresSafeArea()
                            ProgressView("Loading account...")
                        }
                        .onAppear {
                            viewModel.fetchUser()
                        }
                    }
                }
            } else {
                LoginView()
                    .environmentObject(viewModel)
            }
        }
    }
}
