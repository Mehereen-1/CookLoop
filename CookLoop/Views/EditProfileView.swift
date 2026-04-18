//
//  EditProfileView.swift
//  CookLoop
//
//  Created by Ayesha Meherin on 27/3/26.
//

import SwiftUI
import UIKit
import FirebaseAuth

struct EditProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var name = ""
    @State private var bio = ""
    @State private var email = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""

    @State private var isSavingProfile = false
    @State private var isChangingPassword = false
    @State private var infoMessage = ""
    @State private var errorMessage = ""
    @State private var showPasswordSection = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        AppTopBar(
                            title: "CookLoop",
                            subtitle: "Edit profile",
                            showsBackButton: true,
                            trailingSystemIcon: nil,
                            onBackTap: { presentationMode.wrappedValue.dismiss() }
                        )

                        profileImageSection
                        profileBasicsSection
                        accountSection
                        passwordSection
                        saveProfileButton

                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.surfaceContainerLowest)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        if !infoMessage.isEmpty {
                            Text(infoMessage)
                                .font(.subheadline)
                                .foregroundColor(.green)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.surfaceContainerLowest)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("")
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .onAppear {
            name = viewModel.user?.name ?? ""
            bio = viewModel.user?.bio ?? ""
            email = viewModel.user?.email ?? Auth.auth().currentUser?.email ?? ""
        }
    }

    private var profileImageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Profile photo")

            HStack(spacing: 14) {
                Group {
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFill()
                    } else if let profileImage = viewModel.user?.profileImage,
                              !profileImage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        RemoteImageView(urlString: profileImage)
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color.surfaceContainer)
                            Image(systemName: "person.fill")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.primaryBrand)
                        }
                    }
                }
                .frame(width: 86, height: 86)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.outlineVariant.opacity(0.3), lineWidth: 1)
                )

                VStack(alignment: .leading, spacing: 8) {
                    Button(action: { showImagePicker = true }) {
                        Label("Upload profile picture", systemImage: "photo.badge.plus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primaryBrand)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(Color.surfaceContainerLowest)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    if selectedImage != nil {
                        Button(action: { selectedImage = nil }) {
                            Text("Remove selected image")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }

                Spacer()
            }
        }
        .padding(14)
        .background(Color.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var profileBasicsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Profile")

            fieldLabel("Name")
            TextField("Enter your name", text: $name)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.surfaceContainerLowest)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            fieldLabel("Bio")
            TextEditor(text: $bio)
                .frame(minHeight: 90)
                .padding(8)
                .background(Color.surfaceContainerLowest)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(14)
        .background(Color.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Account")

            fieldLabel("Email")
            TextField("", text: $email)
                .disabled(true)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.surfaceContainerLowest)
                .foregroundColor(.onSurfaceVariant)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Text("Email is read-only and tied to your login.")
                .font(.caption)
                .foregroundColor(.onSurfaceVariant)
        }
        .padding(14)
        .background(Color.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var passwordSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showPasswordSection.toggle()
                }
            }) {
                HStack {
                    Text("Change Password")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.onSurface)

                    Spacer()

                    Image(systemName: showPasswordSection ? "chevron.up" : "chevron.down")
                        .foregroundColor(.onSurfaceVariant)
                }
            }

            if showPasswordSection {
                fieldLabel("Current password")
                SecureField("Current password", text: $currentPassword)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.surfaceContainerLowest)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                fieldLabel("New password")
                SecureField("New password", text: $newPassword)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.surfaceContainerLowest)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                fieldLabel("Confirm new password")
                SecureField("Confirm new password", text: $confirmPassword)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.surfaceContainerLowest)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Button(action: changePassword) {
                    if isChangingPassword {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .onPrimary))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    } else {
                        Text("Update Password")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
                .disabled(isChangingPassword)
                .background(isChangingPassword ? Color.primaryBrand.opacity(0.7) : Color.primaryBrand)
                .foregroundColor(.onPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(14)
        .background(Color.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var saveProfileButton: some View {
        Button(action: saveProfile) {
            if isSavingProfile {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .onPrimary))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            } else {
                Text("Save Profile Changes")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
        }
        .disabled(isSavingProfile)
        .background(isSavingProfile ? Color.primaryBrand.opacity(0.7) : Color.primaryBrand)
        .foregroundColor(.onPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .foregroundColor(.onSurface)
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .foregroundColor(.onSurfaceVariant)
    }

    private func saveProfile() {
        let cleanedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedName.isEmpty else {
            infoMessage = ""
            errorMessage = "Name cannot be empty."
            return
        }

        errorMessage = ""
        infoMessage = ""
        isSavingProfile = true

        let encodedProfileImage = selectedImage.flatMap { encodedImageDataURL(from: $0) }
        if selectedImage != nil && encodedProfileImage == nil {
            isSavingProfile = false
            errorMessage = "Selected image is too large. Please choose a smaller one."
            return
        }

        viewModel.updateProfile(name: cleanedName, bio: bio, profileImage: encodedProfileImage) { success, message in
            isSavingProfile = false

            if success {
                infoMessage = "Profile updated successfully."
                errorMessage = ""
            } else {
                infoMessage = ""
                errorMessage = message ?? "Unable to save profile changes."
            }
        }
    }

    private func changePassword() {
        let current = currentPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let proposed = newPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let confirm = confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !current.isEmpty, !proposed.isEmpty, !confirm.isEmpty else {
            infoMessage = ""
            errorMessage = "Please fill all password fields."
            return
        }

        guard proposed.count >= 6 else {
            infoMessage = ""
            errorMessage = "New password must be at least 6 characters."
            return
        }

        guard proposed == confirm else {
            infoMessage = ""
            errorMessage = "New passwords do not match."
            return
        }

        isChangingPassword = true
        errorMessage = ""
        infoMessage = ""

        viewModel.changePassword(currentPassword: current, newPassword: proposed) { success, message in
            isChangingPassword = false

            if success {
                currentPassword = ""
                newPassword = ""
                confirmPassword = ""
                infoMessage = "Password updated successfully."
                errorMessage = ""
            } else {
                infoMessage = ""
                errorMessage = message ?? "Unable to update password."
            }
        }
    }

    private func encodedImageDataURL(from image: UIImage) -> String? {
        let resized = resizedImage(image, maxDimension: 900)
        guard let compressedData = compressedJPEGData(for: resized, maxBytes: 550_000) else { return nil }
        return "data:image/jpeg;base64,\(compressedData.base64EncodedString())"
    }

    private func resizedImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard size.width > maxDimension || size.height > maxDimension else { return image }

        let scale = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    private func compressedJPEGData(for image: UIImage, maxBytes: Int) -> Data? {
        var compression: CGFloat = 0.82
        guard var data = image.jpegData(compressionQuality: compression) else { return nil }

        while data.count > maxBytes && compression > 0.28 {
            compression -= 0.08
            guard let updatedData = image.jpegData(compressionQuality: compression) else { break }
            data = updatedData
        }

        return data.count <= maxBytes ? data : nil
    }
}
