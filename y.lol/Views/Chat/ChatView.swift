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
    @State private var isShowingMediaPicker = false
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
    
    // Add the scenePhase environment value
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var isDrawerOpen = false
    @State private var isThinking = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                NavigationView {
                    VStack {
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
                                            isThinking: $isThinking,
                                            showProfile: $showProfile,
                                            isDrawerOpen: $isDrawerOpen,
                                            currentMode: viewModel.currentMode,
                                            onPillTapped: { mode in
                                                viewModel.currentMode = mode
                                                print("Switched to mode: \(mode)")
                                            },
                                            onSaveChat: {
                                                viewModel.saveCurrentChatSession()
                                            }
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
                                                        isShowingMediaPicker = true
                                                    } else {
                                                        permissionAlertType = "Camera"
                                                        showPermissionAlert = true
                                                    }
                                                    isActionsExpanded = false
                                                },
                                                onPhotoLibraryButtonTapped: {
                                                    permissionManager.checkPhotoLibraryPermission()
                                                    if permissionManager.photoLibraryPermissionGranted {
                                                        sourceType = .photoLibrary
                                                        isShowingMediaPicker = true
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
                                    .sheet(isPresented: $isShowingMediaPicker) {
                                        if sourceType == .camera {
                                            CameraView(selectedImage: $selectedImage)
                                                .onDisappear {
                                                    if let image = selectedImage {
                                                        handleSelectedImage(image)
                                                    }
                                                }
                                        } else {
                                            PhotosPickerView(
                                                selectedImage: $selectedImage,
                                                selectedImageUrl: $selectedImageUrl,
                                                isPresented: $isShowingMediaPicker,
                                                onImageSelected: { image, url in
                                                    handleSelectedImage(image)
                                                    selectedImageUrl = url
                                                }
                                            )
                                            .presentationDetents([.medium, .large])
                                        }
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
                }
                .frame(width: geometry.size.width)
                .offset(x: isDrawerOpen ? geometry.size.width * 0.75 : 0)
                .disabled(isDrawerOpen) // Disable interaction when drawer is open
                .animation(.easeInOut, value: isDrawerOpen)

                if isDrawerOpen {
                    DrawerView(conversations: viewModel.previousConversations)
                        .frame(width: geometry.size.width * 0.8)
                        .background(Color.white)
                        .shadow(radius: 5)
                        .transition(.move(edge: .leading))
                }
            }
            .gesture(DragGesture()
                .onEnded { value in
                    if value.translation.width < -100 {
                        withAnimation {
                            isDrawerOpen = false
                        }
                    }
                }
            )
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
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                print("App is moving to the background. Saving chat session.")
                viewModel.saveCurrentChatSession()
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
