//
//  ChatView.swift
//  y.lol
//
//  Created by Andrea Russo on 3/13/25.
//

import Foundation
import SwiftUI
import FirebaseAuth
import PhotosUI
import AVFoundation

struct ChatView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.themeColors) private var colors
    
    @StateObject var viewModel = ChatViewModel()
    @State private var showProfile = false
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var isAuthenticated = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    @State private var messageText: String = ""
    @FocusState private var isFocused: Bool
    
    // For message editing
    @State private var isEditing: Bool = false
    private let hapticService = HapticService()
    
    // Add this state variable at the top with other @State properties
    @State private var isActionsExpanded: Bool = false
    
    // Add an auth state listener
    @State private var authStateListener: AuthStateDidChangeListenerHandle?
    
    // Add these state variables to your view
    @State private var isShowingCamera = false
    @State private var isShowingPhotoLibrary = false
    @State private var selectedImage: UIImage?
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    
    // Add these for PhotosPicker
    @State private var selectedItem: PhotosPickerItem?
    @State private var isPhotosPickerPresented = false
    
    // Add this to your view
    @StateObject private var permissionManager = PermissionManager()
    @State private var showPermissionAlert = false
    @State private var permissionAlertType = ""
    
    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView()
                    .environmentObject(authManager)
            } else if !isAuthenticated {
                LoginView()
                    .environmentObject(authManager)
            } else {
                GeometryReader { geometry in
                    ZStack {
                        // Background with texture
                        colors.backgroundWithNoise
                            .ignoresSafeArea()
                        
                        VStack(spacing: 0) {
                            HeaderView(isThinking: $viewModel.isThinking, showProfile: $showProfile)
                            
                            ScrollViewReader { proxy in
                                ScrollView {
                                    LazyVStack(spacing: 12) {
                                        ForEach(viewModel.messages) { message in
                                            MessageView(message: message, index: 0, totalCount: viewModel.messages.count)
                                                .id(message.id)
                                                .transition(.asymmetric(
                                                    insertion: .modifier(
                                                        active: CustomTransitionModifier(offset: 20, opacity: 0, scale: 0.8),
                                                        identity: CustomTransitionModifier(offset: 0, opacity: 1, scale: 1.0)
                                                    ),
                                                    removal: .opacity.combined(with: .scale(scale: 0.9))
                                                ))
                                        }
                                        
                                        // Add typing indicator
                                        if viewModel.isTyping {
                                            HStack {
                                                TypingIndicatorView()
                                                Spacer()
                                            }
                                            .padding(.horizontal)
                                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                                        }
                                    }
                                    .padding(.vertical)
                                }
                                .onChange(of: viewModel.messages.count) { oldCount, newCount in
                                    if newCount > oldCount {
                                        scrollToLatest(proxy: proxy)
                                    }
                                }
                                // Also scroll when typing indicator appears
                                .onChange(of: viewModel.isTyping) { _, isTyping in
                                    if isTyping {
                                        scrollToLatest(proxy: proxy)
                                    }
                                }
                            }
                            
                            // Action Pills and Input area
                            VStack {
                                if !isActionsExpanded {
                                    ActionPillsView(currentMode: viewModel.currentMode) { mode in
                                        handlePillTap(mode)
                                    }
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                                }
                                
                                MessageInputView(
                                    messageText: $messageText,
                                    isActionsExpanded: $isActionsExpanded,
                                    selectedImage: $selectedImage,
                                    onSend: sendMessage,
                                    onCameraButtonTapped: {
                                        permissionManager.checkCameraPermission()
                                        if permissionManager.cameraPermissionGranted {
                                            sourceType = .camera
                                            isShowingCamera = true
                                        } else {
                                            permissionAlertType = "Camera"
                                            showPermissionAlert = true
                                        }
                                    },
                                    onPhotoLibraryButtonTapped: {
                                        permissionManager.checkPhotoLibraryPermission()
                                        if permissionManager.photoLibraryPermissionGranted {
                                            isPhotosPickerPresented = true
                                        } else {
                                            permissionAlertType = "Photo Library"
                                            showPermissionAlert = true
                                        }
                                    }
                                )
                                .padding()
                            }
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActionsExpanded)
                        }
                        .onChange(of: viewModel.isThinking) { oldValue, newValue in
                            if newValue {
                                hapticService.startBreathing()
                            } else {
                                hapticService.stopBreathing()
                            }
                        }
                        .sheet(isPresented: $showProfile) {
                            ProfileView()
                                .environmentObject(authManager)
                        }
                        .sheet(isPresented: $isShowingCamera) {
                            ImagePicker(selectedImage: $selectedImage, sourceType: sourceType)
                                .onDisappear {
                                    if let image = selectedImage {
                                        handleSelectedImage(image)
                                    }
                                }
                        }
                        .sheet(isPresented: $isPhotosPickerPresented) {
                            PhotosPickerView(
                                selectedImage: $selectedImage,
                                isPresented: $isPhotosPickerPresented,
                                onImageSelected: { image in
                                    handleSelectedImage(image)
                                }
                            )
                            .presentationDetents([.medium, .large])
                        }
                        .alert(isPresented: $showPermissionAlert) {
                            Alert(
                                title: Text("\(permissionAlertType) Access Required"),
                                message: Text("Please allow access to your \(permissionAlertType.lowercased()) in Settings to use this feature."),
                                primaryButton: .default(Text("Open Settings")) {
                                    permissionManager.openAppSettings()
                                },
                                secondaryButton: .cancel()
                            )
                        }
                    }
                }
            }
        }
        .onAppear {
            setupAuthListener()
            checkAuthStatus()
            print("Debug - ChatView appeared, auth status: \(isAuthenticated)")
        }
        .onDisappear {
            // Remove listener when view disappears
            if let listener = authStateListener {
                Auth.auth().removeStateDidChangeListener(listener)
            }
        }
    }
    
    private func setupAuthListener() {
        // Remove existing listener if any
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
        
        // Set up a new listener
        authStateListener = Auth.auth().addStateDidChangeListener { auth, user in
            print("Debug - Auth state changed, user: \(user?.uid ?? "nil")")
            isAuthenticated = user != nil
        }
    }
    
    private func checkAuthStatus() {
        let wasAuthenticated = isAuthenticated
        isAuthenticated = Auth.auth().currentUser != nil
        
        print("Debug - Manual auth check: \(isAuthenticated)")
        
        if !wasAuthenticated && isAuthenticated {
            print("Debug - User just became authenticated")
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty || selectedImage != nil else { return }
        
        viewModel.messageText = messageText

        let imageToSend = selectedImage

        DispatchQueue.main.async {
            self.messageText = ""
        }
        
        // Send the message to the LLM
            Task {
                await viewModel.sendMessage(with: imageToSend)
                selectedImage = nil
            }
    }
    
    private func scrollToLatest(proxy: ScrollViewProxy) {
        guard let lastMessage = viewModel.messages.last else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
    
    // Add this function to handle pill taps
    private func handlePillTap(_ mode: FirebaseManager.ChatMode) {
        viewModel.currentMode = mode
        print("Switched to mode: \(mode)")
    }
    
    // Modify this function to just set the selectedImage without sending it
    private func handleSelectedImage(_ image: UIImage) {
        // Just set the selected image without sending it
        selectedImage = image
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}




// ImagePicker for camera
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    var sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// PHPickerView for photo library
struct PHPickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PHPickerView
        
        init(_ parent: PHPickerView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                    }
                }
            }
        }
    }
}


