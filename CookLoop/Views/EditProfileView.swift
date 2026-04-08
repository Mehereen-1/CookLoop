//
//  EditProfileView.swift
//  CookLoop
//
//  Created by Ayesha Meherin on 27/3/26.
//

import SwiftUI

struct EditProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var name = ""
    @State private var bio = ""

    var body: some View {
        VStack(spacing: 20) {

            Text("Edit Profile")
                .font(.title)
                .fontWeight(.bold)

            TextField("Name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("Bio", text: $bio)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button("Save") {
                viewModel.updateProfile(name: name, bio: bio)
                presentationMode.wrappedValue.dismiss()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
        .onAppear {
            name = viewModel.user?.name ?? ""
            bio = viewModel.user?.bio ?? ""
        }
    }
}
