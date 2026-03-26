//
//  UploadView.swift
//  CookLoop
//
//  Created by Ayesha Meherin on 26/3/26.
//

import SwiftUI

struct UploadView: View {
    @State private var title = ""
    @State private var ingredients = ""
    @State private var steps = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {

                    Button(action: {}) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 200)

                            Text("Upload Image")
                                .foregroundColor(.gray)
                        }
                    }

                    TextField("Recipe Title", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    TextField("Ingredients (comma separated)", text: $ingredients)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    TextField("Steps", text: $steps)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button(action: {
                        print("Upload tapped")
                    }) {
                        Text("Post Recipe")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
            .navigationTitle("Upload")
        }
    }
}

struct UploadView_Previews: PreviewProvider {
    static var previews: some View {
        UploadView()
    }
}
