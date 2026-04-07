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
        VStack(spacing: 20) {

            Text("Create Account")
                .font(.title)
                .fontWeight(.bold)

            TextField("Name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            if viewModel.isLoading {
                ProgressView()
            }

            Button("Sign Up") {
                viewModel.signup(name: name, email: email, password: password)
                presentationMode.wrappedValue.dismiss()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        SignupView()
    }
}
