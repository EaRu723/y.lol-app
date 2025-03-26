//
//  PhotosPicker.swift
//  y.lol
//
//  Created by Andrea Russo on 3/17/25.
//

import SwiftUI
import PhotosUI

struct PhotosPickerView: View {
    @Binding var selectedImage: UIImage?
    @Binding var selectedImageUrl: String?
    @Binding var isPresented: Bool
    var onImageSelected: ((UIImage, String) -> Void)?
    
    @State private var selectedItem: PhotosPickerItem?
    
    var body: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .images,
            preferredItemEncoding: .current
        ) {
            Label("Change Photo", systemImage: "camera.fill")
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.6))
                .clipShape(Capsule())
        }
        .onChange(of: selectedItem) { _, newItem in
            if let newItem {
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        // Update UI immediately with selected image
                        await MainActor.run {
                            selectedImage = image
                        }
                        
                        // Upload in background
                        FirebaseManager.shared.uploadImage(image) { result in
                            DispatchQueue.main.async {
                                switch result {
                                case .success(let downloadURL):
                                    selectedImageUrl = downloadURL.absoluteString
                                    onImageSelected?(image, downloadURL.absoluteString)
                                case .failure(let error):
                                    print("Debug - Error uploading image: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
