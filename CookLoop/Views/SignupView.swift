//
//  SignupView.swift
//  CookLoop
//
//  Created by Ayesha Meherin on 27/3/26.
//

import SwiftUI

struct SignupView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""

    @EnvironmentObject var viewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    AppTopBar(
                        subtitle: "Create account",
                        showsBackButton: true,
                        trailingSystemIcon: nil,
                        onBackTap: { presentationMode.wrappedValue.dismiss() }
                    )

                    TextField("Name", text: $name)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.surfaceContainerLowest)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

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

                    Button(action: {
                        viewModel.signup(name: name, email: email, password: password)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .onPrimary))
                            }

                            Text("Sign Up")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundColor(.onPrimary)
                        .background(Color.primaryBrand)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(viewModel.isLoading)
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
    }
}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        SignupView()
    }
}
