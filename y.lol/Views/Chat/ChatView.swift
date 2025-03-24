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
    @State private var isSearching = false  // New state for search functionality

    var body: some View {
        GeometryReader { geometry in
            mainContentView(geometry: geometry)
        }
        .withYTheme()
        .onAppear {
            setupAuthListener()
            checkAuthStatus()
            performInitialTokenValidation()
        }
        .onDisappear {
            removeAuthListener()
        }
        .onReceive(authManager.$hasTokenError) { hasError in
            self.hasTokenError = hasError
        }
        .onChange(of: scenePhase) { newPhase in
            handleScenePhaseChange(newPhase)
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private func mainContentView(geometry: GeometryProxy) -> some View {
        NavigationView {
            VStack {
                if !hasCompletedOnboarding {
                    OnboardingView()
                        .environmentObject(authManager)
                } else if !isAuthenticated || authManager.hasTokenError {
                    LoginView()
                        .environmentObject(authManager)
                } else {
                    authenticatedContentView()
                }
            }
        }
        .frame(width: geometry.size.width)
    }
    
    @ViewBuilder
    private func authenticatedContentView() -> some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                colors.backgroundWithNoise
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView()
                    
                    // Add the SearchView component
                    if isSearching {
                        SearchView(
                            isSearching: $isSearching,
                            onSearch: { searchQuery in
                                // Handle search logic here
                                print("Searching for: \(searchQuery)")
                                // After search is complete, you might want to:
                                // isSearching = false
                            }
                        )
                    }
                    
                    // Messages area
                    messagesArea()
                    
                    // Input area
                    inputArea()
                }
                .onChange(of: viewModel.isThinking) { oldValue, newValue in
                    handleThinkingStateChange(oldValue: oldValue, newValue: newValue)
                }
                .sheet(isPresented: $showProfile) {
                    ProfileView()
                        .environmentObject(authManager)
                }
                .sheet(isPresented: $isShowingMediaPicker) {
                    mediaPicker()
                }
                .alert(isPresented: $showPermissionAlert) {
                    permissionAlert()
                }
            }
        }
    }
    
    @ViewBuilder
    private func headerView() -> some View {
        HeaderView(
            isThinking: $isThinking,
            showProfile: $showProfile,
            isSearching: $isSearching,
            currentMode: viewModel.currentMode,
            onPillTapped: { mode in
                viewModel.currentMode = mode
                print("Switched to mode: \(mode)")
            },
            onSaveChat: {
                viewModel.saveCurrentChatSession()
            }
        )
    }
    
    @ViewBuilder
    private func messagesArea() -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                messagesContent(proxy: proxy)
            }
            .onChange(of: viewModel.messages.count) { oldCount, newCount in
                if newCount > oldCount {
                    scrollToLatest(proxy: proxy)
                }
            }
            .onChange(of: viewModel.isTyping) { oldValue, newValue in
                handleTypingStateChange(oldValue: oldValue, newValue: newValue, proxy: proxy)
            }
            .onReceive(Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()) { _ in
                if viewModel.isTyping {
                    scrollToLatest(proxy: proxy)
                }
            }
            .onChange(of: isFocused) { oldValue, newValue in
                if newValue == true {
                    // When the text field becomes focused, scroll to the latest message
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            scrollToLatest(proxy: proxy)
                        }
                    }
                }
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 10)
                .onChanged({ _ in
                    hideKeyboard()
                })
        )
    }
    
    @ViewBuilder
    private func messagesContent(proxy: ScrollViewProxy) -> some View {
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
            
            // Typing indicator
            if viewModel.isTyping {
                typingIndicator(proxy: proxy)
            }
            
            // Bottom spacer
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.clear)
                .id("bottomSpacer")
        }
        .padding(.vertical)
    }
    
    @ViewBuilder
    private func typingIndicator(proxy: ScrollViewProxy) -> some View {
        HStack {
            TypingIndicatorView()
            Spacer()
        }
        .padding(.horizontal)
        .id("typingIndicator")
        .transition(.opacity.combined(with: .move(edge: .bottom)))
        .onAppear {
            // Force scroll when the indicator appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.15)) {
                    proxy.scrollTo("typingIndicator", anchor: .bottom)
                }
            }
        }
    }
    
    @ViewBuilder
    private func inputArea() -> some View {
        VStack {
            MessageInputView(
                messageText: $messageText,
                isActionsExpanded: $isActionsExpanded,
                selectedImage: $selectedImage,
                onSend: sendMessage,
                onCameraButtonTapped: handleCameraButtonTapped,
                onPhotoLibraryButtonTapped: handlePhotoLibraryButtonTapped
            )
            .environmentObject(FirebaseManager.shared)
            .padding(.bottom, 8)
            .focused($isFocused)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActionsExpanded)
    }
    
    @ViewBuilder
    private func mediaPicker() -> some View {
        Group {
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
    }
    
    private func permissionAlert() -> Alert {
        Alert(
            title: Text("\(permissionAlertType) Access Required"),
            message: Text("Please allow access to your \(permissionAlertType.lowercased()) in Settings to use this feature."),
            primaryButton: .default(Text("Open Settings")) {
                permissionManager.openAppSettings()
            },
            secondaryButton: .cancel()
        )
    }
    
    // MARK: - Helper Methods
    
    private func performInitialTokenValidation() {
        Task {
            let isValid = await authManager.validateToken()
            if isValid {
                await MainActor.run {
                    if Auth.auth().currentUser != nil {
                        isAuthenticated = true
                    }
                }
            }
        }
        print("Debug - ChatView appeared, auth status: \(isAuthenticated)")
    }
    
    private func removeAuthListener() {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        if newPhase == .background {
            print("App is moving to the background. Saving chat session.")
            viewModel.saveCurrentChatSession()
        }
    }
    
    private func handleThinkingStateChange(oldValue: Bool, newValue: Bool) {
        if newValue {
            hapticService.startBreathing()
        } else {
            hapticService.stopBreathing()
        }
    }
    
    private func handleTypingStateChange(oldValue: Bool, newValue: Bool, proxy: ScrollViewProxy) {
        if newValue {
            // When typing starts, scroll to typing indicator
            withAnimation(.easeOut(duration: 0.15)) {
                scrollToLatest(proxy: proxy)
            }
        } else if !newValue && oldValue {
            // When typing ends, maintain position momentarily
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo("bottomSpacer", anchor: .bottom)
            }
            
            // Then after a short delay, scroll to the latest message
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeOut(duration: 0.2)) {
                    if let lastMessage = viewModel.messages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private func handleCameraButtonTapped() {
        permissionManager.checkCameraPermission()
        if permissionManager.cameraPermissionGranted {
            sourceType = .camera
            isShowingMediaPicker = true
        } else {
            permissionAlertType = "Camera"
            showPermissionAlert = true
        }
        isActionsExpanded = false
    }
    
    private func handlePhotoLibraryButtonTapped() {
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
        // Use a very short delay to allow layout updates to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            // Use a short animation for smoother transition
            withAnimation(.easeOut(duration: 0.15)) {
                if viewModel.isTyping {
                    // Always scroll to typing indicator when AI is typing
                    proxy.scrollTo("typingIndicator", anchor: .bottom)
                } else if let lastMessage = viewModel.messages.last {
                    // Scroll to last message when new message arrives
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
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
    
    private func hideKeyboard() {
        isFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}
