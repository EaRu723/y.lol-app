//
//  PermissionManager.swift
//  y.lol
//
//  Created by Andrea Russo on 3/17/25.
//

import Foundation
import AVFoundation
import Photos
import SwiftUI

class PermissionManager: ObservableObject {
    @Published var cameraPermissionGranted = false
    @Published var photoLibraryPermissionGranted = false
    
    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.cameraPermissionGranted = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.cameraPermissionGranted = granted
                }
            }
        case .denied, .restricted:
            self.cameraPermissionGranted = false
        @unknown default:
            self.cameraPermissionGranted = false
        }
    }
    
    func checkPhotoLibraryPermission() {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized, .limited:
            self.photoLibraryPermissionGranted = true
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    self.photoLibraryPermissionGranted = status == .authorized || status == .limited
                }
            }
        case .denied, .restricted:
            self.photoLibraryPermissionGranted = false
        @unknown default:
            self.photoLibraryPermissionGranted = false
        }
    }
    
    func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
}
