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
    
    var body: some View {
        // Directly embed the PHPicker within your view
        EmbeddedPhotoPicker(
            selectedImage: $selectedImage,
            selectedImageUrl: $selectedImageUrl,
            isPresented: $isPresented,
            onImageSelected: onImageSelected
        )
        .ignoresSafeArea()
    }
}

struct EmbeddedPhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var selectedImageUrl: String?
    @Binding var isPresented: Bool
    var onImageSelected: ((UIImage, String) -> Void)?
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // Not needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let parent: EmbeddedPhotoPicker
        
        init(_ parent: EmbeddedPhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            if let result = results.first {
                result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] reading, error in
                    if let error = error {
                        print("Error loading image: \(error.localizedDescription)")
                        return
                    }
                    
                    if let image = reading as? UIImage {
                        DispatchQueue.main.async {
                            self?.parent.selectedImage = image
                            
                            // Upload in background
                            FirebaseManager.shared.uploadImage(image) { result in
                                DispatchQueue.main.async {
                                    switch result {
                                    case .success(let downloadURL):
                                        self?.parent.selectedImageUrl = downloadURL.absoluteString
                                        self?.parent.onImageSelected?(image, downloadURL.absoluteString)
                                    case .failure(let error):
                                        print("Debug - Error uploading image: \(error.localizedDescription)")
                                    }
                                    self?.parent.isPresented = false
                                }
                            }
                        }
                    }
                }
            } else {
                // User cancelled
                DispatchQueue.main.async {
                    self.parent.isPresented = false
                }
            }
        }
    }
}
