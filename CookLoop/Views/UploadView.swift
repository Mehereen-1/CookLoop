//
//  UploadView.swift
//  CookLoop
//
//  Created by Ayesha Meherin on 26/3/26.
//

import SwiftUI
import UIKit

struct UploadView: View {
        @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel = RecipeViewModel()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let appleIllustrationURL = "https://lh3.googleusercontent.com/aida-public/AB6AXuCsdY0DyUxBiNP812ncyJlL_vjidgmW3kld-sJWafmT-6HhvNbAlLxN7HWVSblcCSGA2FYd2KoJ7VxXDA_e7QRYv-LNd2wBiOXWahepgpg2IDXZxzZxGUTVJvmqleFjBWyAwM3zw0SHBGE33cm-V0ZRFJK5oA6lAGhD3UUk-QDaIxvZuZKjUWdCRhPl3pm7cb1gPDnz1Ab0ITI7iAd6Cjc8CasvB1j4HaFvZsjOGL2XvbfqPl9tUl0QhMMvwOQBo9ozb84JSWSLbAA"
    private let penIllustrationURL = "https://lh3.googleusercontent.com/aida-public/AB6AXuANh1ru5tQg3e7NgGFD4uxf2jkD1llZzYvG4UDQqfAC_fPj9Djnlv48ncHvJ0JpNz4U1HuTR0Py85IJeRDoLgknwEJo42jUR-rABo0Ep4xsCjsWO9eGJZu4J3L-luIw2hax2bwBalQHT0WozsV5VMRmWPkvvi_rhGNtYYfYQ9g1I3xaSZI-OdHDixHpSFDEg8f-My5lay0xBk7-FJ-WxLpXcdWSWOEqHv_VGrUoNEXPEqQR2zd_mujQitcNzMunrp7olnvXgf41eX0"
    private let potIllustrationURL = "https://lh3.googleusercontent.com/aida-public/AB6AXuBRFkdIHVKsCkZIoQUikmcTuCXbWrsRjrOlDDpRUu1AaQ7aBndp4JHk8qiFhvA89K2WudYbSZH1n4kRpnkPQpBXMoFZlEa9gMMVNt3D8X7cyBT8O8FDVcQur1vz9-j1Otrponf_5MAb1Q0d09jMkk_gKJepLPhwqAoZ9uHKSbwohH9a0hPgiKk0nGaNfjE6lISrpO-v9tMA1issuT39TJ7uRCech72A53H-lc8MT1EkqL7PzaXmXS7pM0bYORlCiZiugv5mPg94UNA"

    @State private var title = ""
    @State private var imageUrl = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false

    @State private var cookingTimeMinutes = 30
    @State private var selectedDifficulty = "Intermediate"
    @State private var selectedTags: Set<String> = []

    @State private var ingredientInput = ""
    @State private var ingredients: [String] = []
    @State private var steps: [String] = [""]
    @State private var showSearch = false

    private let difficultyOptions = ["Easy", "Intermediate", "Hard"]
    private let tagOptions = [
        "Spicy Dinners",
        "Sweet Treats",
        "Quick Fixes",
        "Healthy Bowls",
        "Cozy Breakfasts",
        "Vegan",
        "Comfort Food"
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        AppTopBar(subtitle: "Share your kitchen creation", onTrailingTap: { showSearch = true })

                        headerSection
                        titleSection
                        mediaAndTipSection
                        recipeMetaSection
                        bentoContentSection
                        submitSection

                        if !viewModel.errorMessage.isEmpty {
                            Text(viewModel.errorMessage)
                                .foregroundColor(.red)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.surfaceContainerLowest)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 0)
                    .padding(.bottom, 120)
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
        .onChange(of: selectedImage) { newImage in
            guard let newImage = newImage else { return }

            if let dataUrl = encodedImageDataURL(from: newImage) {
                imageUrl = dataUrl
                viewModel.errorMessage = ""
            } else {
                imageUrl = ""
                viewModel.errorMessage = "Image is too large. Please choose a smaller image."
            }
        }
        .sheet(isPresented: $showSearch) {
            SearchRecipesSheet()
        }
    }

    private var headerSection: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Write Your\nNext Chapter")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundColor(.primaryBrand)
                    .lineSpacing(-2)

                Text("Every meal is a memory. Capture yours with warmth and flavor.")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.onSurfaceVariant)
                    .frame(maxWidth: 310, alignment: .leading)
            }

            RemoteImageView(urlString: appleIllustrationURL)
                .frame(width: 78, height: 78)
                .rotationEffect(.degrees(10))
                .offset(x: -6, y: 2)
        }
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What's the dish called?")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.onSurface)

            ZStack(alignment: .bottomTrailing) {
                TextField("Grandma's Magic Stew...", text: $title)
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(.primaryBrand)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .padding(.trailing, 56)
                    .background(Color.surfaceContainer)
                    .clipShape(RoundedRectangle(cornerRadius: 24))

                RemoteImageView(urlString: penIllustrationURL)
                    .frame(width: 52, height: 52)
                    .offset(x: -10, y: 10)
            }
        }
    }

    private var mediaAndTipSection: some View {
        Group {
            if horizontalSizeClass == .regular {
                HStack(spacing: 14) {
                    imageCard
                    tipCard
                }
            } else {
                VStack(spacing: 14) {
                    imageCard
                    tipCard
                }
            }
        }
    }

    private var imageCard: some View {
        VStack(spacing: 12) {
            Group {
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                } else if imageUrl.isEmpty {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.surfaceContainerLow)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.primaryBrand)
                                Text("Add a tasty photo")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.onSurface)
                            }
                        )
                } else {
                    RemoteImageView(urlString: imageUrl)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
            }
            .frame(height: 220)

            Button(action: { showImagePicker = true }) {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                    Text(selectedImage == nil ? "Choose Image from Device" : "Choose Different Image")
                        .fontWeight(.semibold)
                    Spacer()
                }
                .foregroundColor(.primaryBrand)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.surfaceContainerLowest)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(14)
        .background(Color.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .frame(maxWidth: .infinity)
    }

    private var tipCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Cooking Tip")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(.onSecondaryContainer)

            Text("\"The best recipes are shared over laughter and warm tea.\"")
                .font(.system(size: 16, weight: .medium))
                .italic()
                .foregroundColor(.onSecondaryContainer)

            Spacer(minLength: 0)

            HStack {
                Spacer()
                RemoteImageView(urlString: potIllustrationURL)
                    .frame(width: 110, height: 110)
                    .rotationEffect(.degrees(-8))
            }
        }
        .padding(18)
        .background(Color.secondaryContainer)
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .frame(maxWidth: .infinity, minHeight: 220)
    }

    private var recipeMetaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recipe Details")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundColor(.onSurface)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Approx Cooking Time")
                        .font(.subheadline)
                        .foregroundColor(.onSurfaceVariant)
                    Spacer()
                    Text("\(cookingTimeMinutes) min")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryBrand)
                }

                Stepper("", value: $cookingTimeMinutes, in: 5...240, step: 5)
                    .labelsHidden()
            }
            .padding(12)
            .background(Color.surfaceContainerLowest)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 8) {
                Text("Difficulty")
                    .font(.subheadline)
                    .foregroundColor(.onSurfaceVariant)

                Picker("Difficulty", selection: $selectedDifficulty) {
                    ForEach(difficultyOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding(12)
            .background(Color.surfaceContainerLowest)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 8) {
                Text("Tags")
                    .font(.subheadline)
                    .foregroundColor(.onSurfaceVariant)

                FlexibleTagWrap(tags: tagOptions, selectedTags: $selectedTags)
            }
            .padding(12)
            .background(Color.surfaceContainerLowest)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var bentoContentSection: some View {
        Group {
            if horizontalSizeClass == .regular {
                HStack(alignment: .top, spacing: 12) {
                    ingredientsSection
                    stepsSection
                }
            } else {
                VStack(spacing: 12) {
                    ingredientsSection
                    stepsSection
                }
            }
        }
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "list.bullet")
                    .foregroundColor(.primaryBrand)
                Text("Ingredients")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundColor(.onSurface)
            }

            HStack(spacing: 8) {
                TextField("2 cups flour", text: $ingredientInput)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.surfaceContainerLowest)
                    .clipShape(Capsule())

                Button(action: addIngredient) {
                    Image(systemName: "plus")
                        .font(.headline)
                        .foregroundColor(.onPrimary)
                        .frame(width: 40, height: 40)
                        .background(Color.primaryBrand)
                        .clipShape(Circle())
                }
            }

            VStack(spacing: 8) {
                ForEach(ingredients, id: \.self) { ingredient in
                    HStack {
                        Text(ingredient)
                            .font(.subheadline)
                            .foregroundColor(.onSurface)
                        Spacer()
                        Button(action: { removeIngredient(ingredient) }) {
                            Image(systemName: "xmark")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.surfaceContainerLowest.opacity(0.7))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .background(Color.surfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .onSurface.opacity(0.05), radius: 10, x: 6, y: 6)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "book")
                    .foregroundColor(.primaryBrand)
                Text("Cooking Steps")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundColor(.onSurface)
            }

            VStack(spacing: 12) {
                ForEach(steps.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.caption)
                            .fontWeight(.black)
                            .foregroundColor(.onPrimary)
                            .frame(width: 28, height: 28)
                            .background(Color.primaryBrand)
                            .clipShape(Circle())

                        TextEditor(text: Binding(
                            get: { steps[index] },
                            set: { steps[index] = $0 }
                        ))
                        .frame(minHeight: 90)
                        .padding(8)
                        .background(Color.surfaceContainerLow)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        if steps.count > 1 {
                            Button(action: { removeStep(at: index) }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .padding(.top, 8)
                        }
                    }
                }

                Button(action: addStep) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                        Text("Add the next step")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundColor(.onSurfaceVariant)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.outlineVariant, style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                    )
                }
            }
        }
        .padding(16)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.surfaceContainer.opacity(0.9), lineWidth: 1)
        )
        .shadow(color: .onSurface.opacity(0.04), radius: 12, x: 8, y: 8)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var submitSection: some View {
        VStack(spacing: 8) {
            Button(action: uploadRecipe) {
                HStack(spacing: 8) {
                    if viewModel.isUploading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .onPrimary))
                    }

                    Text("Publish My Story")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.primaryBrand)
                .foregroundColor(.onPrimary)
                .clipShape(Capsule())
                .shadow(color: Color.primaryBrand.opacity(0.25), radius: 16, x: 0, y: 10)
            }
            .disabled(viewModel.isUploading)

            Text("Ready to be shared with the world!")
                .font(.footnote)
                .foregroundColor(.onSurfaceVariant)
        }
        .padding(.top, 8)
    }

    private func uploadRecipe() {
        guard !imageUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            viewModel.errorMessage = "Please select an image from your device."
            return
        }

        let cleanedIngredients = ingredients
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let cleanedSteps = steps
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !cleanedIngredients.isEmpty else {
            viewModel.errorMessage = "Please add at least one ingredient."
            return
        }

        guard !cleanedSteps.isEmpty else {
            viewModel.errorMessage = "Please add at least one cooking step."
            return
        }

        viewModel.uploadRecipe(
            title: title,
            ingredients: cleanedIngredients,
            steps: cleanedSteps,
            imageUrl: imageUrl,
            cookingTimeMinutes: cookingTimeMinutes,
            difficulty: selectedDifficulty,
            tags: Array(selectedTags)
        ) { success in
            if success {
                clearFields()
            }
        }
    }

    private func clearFields() {
        title = ""
        imageUrl = ""
        selectedImage = nil
        cookingTimeMinutes = 30
        selectedDifficulty = "Intermediate"
        selectedTags.removeAll()
        ingredientInput = ""
        ingredients = []
        steps = [""]
    }

    private func addIngredient() {
        let trimmed = ingredientInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        ingredients.append(trimmed)
        ingredientInput = ""
    }

    private func removeIngredient(_ ingredient: String) {
        if let idx = ingredients.firstIndex(of: ingredient) {
            ingredients.remove(at: idx)
        }
    }

    private func addStep() {
        steps.append("")
    }

    private func removeStep(at index: Int) {
        guard steps.indices.contains(index) else { return }
        steps.remove(at: index)
    }

    private func encodedImageDataURL(from image: UIImage) -> String? {
        let resized = resizeImageIfNeeded(image, maxDimension: 1280)
        guard let compressedData = compressedJPEGData(for: resized, maxBytes: 650_000) else { return nil }
        return "data:image/jpeg;base64,\(compressedData.base64EncodedString())"
    }

    private func resizeImageIfNeeded(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let width = image.size.width
        let height = image.size.height
        let largest = max(width, height)
        guard largest > maxDimension else { return image }

        let scale = maxDimension / largest
        let newSize = CGSize(width: width * scale, height: height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage ?? image
    }

    private func compressedJPEGData(for image: UIImage, maxBytes: Int) -> Data? {
        var compression: CGFloat = 0.85
        let minimumCompression: CGFloat = 0.2

        guard var data = image.jpegData(compressionQuality: compression) else { return nil }

        while data.count > maxBytes && compression > minimumCompression {
            compression -= 0.1
            guard let updatedData = image.jpegData(compressionQuality: compression) else { break }
            data = updatedData
        }

        return data.count <= maxBytes ? data : nil
    }
}

private struct FlexibleTagWrap: View {
    let tags: [String]
    @Binding var selectedTags: Set<String>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { tag in
                        Button(action: {
                            if selectedTags.contains(tag) {
                                selectedTags.remove(tag)
                            } else {
                                selectedTags.insert(tag)
                            }
                        }) {
                            Text(tag)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(selectedTags.contains(tag) ? .onSecondaryContainer : .onSurfaceVariant)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(selectedTags.contains(tag) ? Color.secondaryContainer : Color.surfaceContainerLow)
                                .clipShape(Capsule())
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var rows: [[String]] {
        var result: [[String]] = []
        var currentRow: [String] = []

        for (index, tag) in tags.enumerated() {
            currentRow.append(tag)
            if currentRow.count == 3 || index == tags.count - 1 {
                result.append(currentRow)
                currentRow = []
            }
        }

        return result
    }
}

struct UploadView_Previews: PreviewProvider {
    static var previews: some View {
        UploadView()
    }
}
