//
//  LoginView.swift
//  CookLoop
//
//  Created by Ayesha Meherin on 27/3/26.
//

import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showSignup = false

    @EnvironmentObject var viewModel: AuthViewModel

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {

                Text("CookLoop 🍲")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                if viewModel.isLoading {
                    ProgressView()
                }

                Button("Login") {
                    viewModel.login(email: email, password: password)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(10)

                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                }

                Button("Don't have an account? Sign Up") {
                    showSignup = true
                }
                .sheet(isPresented: $showSignup) {
                    SignupView()
                        .environmentObject(viewModel)
                }
            }
            .padding()
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
