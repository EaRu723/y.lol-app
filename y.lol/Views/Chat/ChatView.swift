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
    
    // Add this to your existing properties
    @State private var hasTokenError: Bool = false
    
    // Add a state property for storing the image URL
    @State private var selectedImageUrl: String?
    
    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView()
                    .environmentObject(authManager)
            } else if !isAuthenticated || authManager.hasTokenError {
                LoginView()
                    .environmentObject(authManager)
            } else {
                GeometryReader { geometry in
                    ZStack {
                        // Background
                        colors.backgroundWithNoise
                            .ignoresSafeArea()
                        
                        VStack(spacing: 0) {
                            HeaderView(
                                isThinking: $viewModel.isThinking, 
                                showProfile: $showProfile,
                                currentMode: viewModel.currentMode,
                                onPillTapped: handlePillTap
                            )
                            
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
                                        isActionsExpanded = false
                                    },
                                    onPhotoLibraryButtonTapped: {
                                        permissionManager.checkPhotoLibraryPermission()
                                        if permissionManager.photoLibraryPermissionGranted {
                                            isPhotosPickerPresented = true
                                        } else {
                                            permissionAlertType = "Photo Library"
                                            showPermissionAlert = true
                                        }
                                        isActionsExpanded = false
                                    }
                                )
                                .environmentObject(FirebaseManager.shared)
                                .padding(.bottom, 8)
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
                                selectedImageUrl: $selectedImageUrl,
                                isPresented: $isPhotosPickerPresented,
                                onImageSelected: { image, url in
                                    handleSelectedImage(image)
                                    // Store the URL if needed
                                    selectedImageUrl = url
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
        .withYTheme()
        .onAppear {
            setupAuthListener()
            checkAuthStatus()
            // Add token validation
            Task {
                let isValid = await authManager.validateToken()
                if isValid {
                    // If token is valid, make sure UI reflects authenticated state
                    await MainActor.run {
                        if Auth.auth().currentUser != nil {
                            isAuthenticated = true
                        }
                    }
                }
            }
            print("Debug - ChatView appeared, auth status: \(isAuthenticated)")
        }
        .onDisappear {
            // Remove listener when view disappears
            if let listener = authStateListener {
                Auth.auth().removeStateDidChangeListener(listener)
            }
        }
        // Add an observer for token errors
        .onReceive(authManager.$hasTokenError) { hasError in
            self.hasTokenError = hasError
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
        
        // Store message content locally before clearing
        let messageToSend = messageText
        let imageToSend = selectedImage
        
        // Clear input immediately
        withAnimation(.easeOut(duration: 0.2)) {
            messageText = ""
            selectedImage = nil
        }
        
        // Use local copies for sending
        viewModel.messageText = messageToSend
        
        // Send the message to the LLM
        Task {
            await viewModel.sendMessage(with: imageToSend)
            
            // Force clear selectedImage again on the main thread after task completes
            await MainActor.run {
                selectedImage = nil
            }
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
        // Add a guard to prevent setting image if it's being cleared
        if viewModel.isThinking {
            return // Don't set image while message is being sent
        }
        
        // Just set the selected image without sending it
        selectedImage = image
    }
    
    private func makeAuthenticatedRequest() async {
        do {
            // Attempt to validate token before making requests
            await authManager.validateToken()
            
            // If we have a token error, don't proceed with the request
            guard !authManager.hasTokenError else {
                return
            }
            
            // Continue with your authenticated request...
        } catch {
            print("Request error: \(error.localizedDescription)")
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}

// Keep the ImagePicker implementation
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
