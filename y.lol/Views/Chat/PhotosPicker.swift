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
    @Binding var isPresented: Bool
    var onImageSelected: ((UIImage) -> Void)?
    
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
                        DispatchQueue.main.async {
                            selectedImage = image
                            if let onImageSelected = onImageSelected {
                                onImageSelected(image)
                            }
                            isPresented = false
                        }
                    }
                }
            }
        }
    }
}
