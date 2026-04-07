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
                ContentView() // will add later
                    .environmentObject(viewModel)
            } else {
                LoginView()
                    .environmentObject(viewModel)
            }
        }
    }
}
