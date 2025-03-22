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
            preferredItemEncoding: .current,
            photoLibrary: .shared()
        ) {
            Label("Select a photo", systemImage: "photo")
        }
        .photosPickerStyle(.inline)
        .onChange(of: selectedItem) { _, newItem in
            if let newItem {
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        
                        FirebaseManager.shared.uploadImage(image) { result in
                            DispatchQueue.main.async {
                                switch result {
                                case .success(let downloadURL):
                                    selectedImage = image
                                    selectedImageUrl = downloadURL.absoluteString
                                    onImageSelected?(image, downloadURL.absoluteString)
                                    isPresented = false // Hide loading indicator / re-enable send button
                                    print("Debug - Image uploaded successfully: \(downloadURL)")
                                case .failure(let error):
                                    // TODO: Handle error
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
