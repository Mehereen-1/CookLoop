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
    @State private var showSearch = false

    @EnvironmentObject var viewModel: AuthViewModel

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        AppTopBar(subtitle: "Welcome back to your kitchen story", onTrailingTap: { showSearch = true })
                            .padding(.top, 10)

                        VStack(spacing: 14) {
                            TextField("Email", text: $email)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.surfaceContainerLowest)
                                .clipShape(RoundedRectangle(cornerRadius: 16))

                            SecureField("Password", text: $password)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.surfaceContainerLowest)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }

                        Button(action: {
                            viewModel.login(email: email, password: password)
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .onPrimary))
                                }

                                Text("Login")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundColor(.onPrimary)
                            .background(Color.primaryBrand)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(viewModel.isLoading)

                        if !viewModel.errorMessage.isEmpty {
                            Text(viewModel.errorMessage)
                                .font(.footnote)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button("Don't have an account? Sign Up") {
                            showSignup = true
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primaryBrand)
                    }
                    .padding(20)
                    .background(Color.surfaceContainerLow)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.outlineVariant.opacity(0.35), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showSignup) {
                SignupView()
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $showSearch) {
                SearchRecipesSheet()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
