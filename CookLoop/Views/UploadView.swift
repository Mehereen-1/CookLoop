//
//  UploadView.swift
//  CookLoop
//
//  Created by Ayesha Meherin on 26/3/26.
//

import SwiftUI

struct UploadView: View {
    @StateObject var viewModel = RecipeViewModel()
    
    @State private var title = ""
    @State private var imageUrl = ""
    @State private var ingredientsText = ""
    @State private var stepsText = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {

                    RemoteImageView(urlString: imageUrl)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(15)
                    
                    TextField("Recipe Title", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    TextField("Image URL", text: $imageUrl)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Ingredients (one per line)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $ingredientsText)
                            .frame(minHeight: 120)
                            .padding(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.35), lineWidth: 1)
                            )
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Steps (one per line)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $stepsText)
                            .frame(minHeight: 140)
                            .padding(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.35), lineWidth: 1)
                            )
                    }
                    
                    Button(action: uploadRecipe) {
                        if viewModel.isUploading {
                            ProgressView()
                        } else {
                            Text("Post Recipe")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    
                    if !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .foregroundColor(.red)
                    }
                }
                .padding()
            }
            .navigationTitle("Upload")
        }
    }
    
    func uploadRecipe() {
        let ingredients = ingredientsText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let steps = stepsText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        viewModel.uploadRecipe(
            title: title,
            ingredients: ingredients,
            steps: steps,
            imageUrl: imageUrl
        ) { success in
            if success {
                clearFields()
            }
        }
    }
    
    func clearFields() {
        title = ""
        imageUrl = ""
        ingredientsText = ""
        stepsText = ""
    }
}
struct UploadView_Previews: PreviewProvider {
    static var previews: some View {
        UploadView()
    }
}
