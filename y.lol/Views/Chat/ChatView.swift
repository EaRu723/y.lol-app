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
    @Environment(\.scenePhase) private var scenePhase
    
    @StateObject var viewModel = ChatViewModel()
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var permissionManager = PermissionManager()
    
    // UI State
    @State private var showProfile = false
    @State private var isSearching = false
    @State private var isThinking = false
    
    // Input State
    @State private var messageText: String = ""
    @FocusState private var isFocused: Bool
    @State private var isEditing: Bool = false
    
    // Media Selection State
    @State private var isShowingMediaPicker = false
    @State private var selectedImage: UIImage?
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var selectedItem: PhotosPickerItem?
    @State private var isPhotosPickerPresented = false
    @State private var selectedImageUrl: String?
    
    // Permission State
    @State private var showPermissionAlert = false
    @State private var permissionAlertType = ""
    
    // Debounce Timer for Image Load Scrolls
    @State private var imageLoadScrollTimer: Timer?
    
    private let hapticService = HapticService()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                colors.backgroundWithNoise
                    .ignoresSafeArea()
                
                // Replace the VStack with ZStack
                ZStack(alignment: .bottom) {
                    VStack(spacing: 0) {
                        headerView()
                        messagesArea() // Remove the .padding(.bottom, 60)
                    }

                    inputArea()
                }
                
                .navigationDestination(isPresented: $showProfile) {
                    ProfileView()
                        .environmentObject(authManager)
                        .navigationBarHidden(true)
                }
                .sheet(isPresented: $isShowingMediaPicker) {
                    mediaPicker()
                }
                .alert(isPresented: $showPermissionAlert) {
                    permissionAlert()
                }
                .onChange(of: viewModel.isThinking) { oldValue, newValue in
                    handleThinkingStateChange(oldValue: oldValue, newValue: newValue)
                }
            }
        }
        .withYTheme()
        .onAppear {
            // Initialize chat state if needed
        }
        .onDisappear {
            // Save any needed state
            viewModel.saveCurrentChatSession()
        }
        .onChange(of: scenePhase) { newPhase in
            handleScenePhaseChange(newPhase)
        }
    }
    
    // MARK: - View Components
    
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
            }
        )
    }
    
    @ViewBuilder
    private func messagesArea() -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                messagesContent(proxy: proxy)
            }
            // Scroll when new messages are added
            .onChange(of: viewModel.messages.count) { oldValueCount, newCount in
                // Only scroll if messages were added (count increased).
                // This ensures scrolling happens even if `isThinking` is briefly true when the message arrives.
                if newCount > oldValueCount {
                    // Add a small delay to allow the new message view to render and layout to settle before scrolling.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { // Increased delay slightly
                       scrollToBottom(proxy: proxy)
                    }
                }
            }
            // Scroll when AI starts/stops typing
            .onChange(of: viewModel.isTyping) { _, isTypingNow in
                if isTypingNow {
                    // When AI starts typing, scroll to make the indicator visible
                    // Add a very slight delay to allow the indicator to appear before scrolling
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        // Explicitly pass the proxy and target the indicator
                        scrollToBottom(proxy: proxy)
                    }
                }
                // No explicit scroll needed when typing stops,
                // as the arrival of the new message will trigger scrolling via .onChange(of: viewModel.messages.count)
            }
            // Scroll when keyboard appears
            .onChange(of: isFocused) { _, isNowFocused in
                if isNowFocused {
                    // When the text field becomes focused, scroll to the bottom
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // Allow keyboard animation
                        scrollToBottom(proxy: proxy)
                    }
                }
            }
            // Scroll when the view initially appears, if needed
            .onAppear {
                 // Scroll to bottom initially if there are messages
                 if !viewModel.messages.isEmpty {
                     DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // Allow layout
                         scrollToBottom(proxy: proxy, animated: false) // Don't animate initial scroll
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
        // Add padding below scroll view to prevent overlap with input area BEFORE keyboard appears
        // Adjust this value based on your MessageInputView's resting height
        // Increased padding value from 50
        .padding(.bottom, 120)
    }
    
    @ViewBuilder
    private func messagesContent(proxy: ScrollViewProxy) -> some View {
        if viewModel.isInitialLoading {
            // Show loading spinner while fetching conversations
            VStack {
                Spacer()
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
                Text("Loading conversations...")
                    .foregroundColor(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            LazyVStack(spacing: 2) { // Keep the reduced spacing for grouped messages
                ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                    let previousMessage = index > 0 ? viewModel.messages[index - 1] : nil
                    let isFirstInGroup = previousMessage?.isUser != message.isUser

                    // --- Timestamp Separator Logic ---
                    // Check if a timestamp separator should be shown before this message
                    if let timestampString = formatTimestampSeparator(current: message.timestamp, previous: previousMessage?.timestamp) {
                        TimestampSeparatorView(text: timestampString)
                            // Add extra top padding if the timestamp is shown, otherwise use standard group padding
                            .padding(.top, 10)
                    }
                    // --- End Timestamp Separator Logic ---

                    MessageView(
                        message: message,
                        index: index,
                        totalCount: viewModel.messages.count,
                        previousMessage: previousMessage,
                        nextMessage: index < viewModel.messages.count - 1 ? viewModel.messages[index + 1] : nil,
                        mode: viewModel.currentMode,
                        onImageLoad: {
                            triggerDebouncedScrollToBottom(proxy: proxy)
                        }
                    )
                    .id(message.id)
                    // Add top padding for message grouping *only if* a timestamp isn't already adding padding
                    .padding(.top, (isFirstInGroup && formatTimestampSeparator(current: message.timestamp, previous: previousMessage?.timestamp) == nil) ? 10 : 0)
                    .transition(.asymmetric(
                        insertion: .modifier(
                            active: CustomTransitionModifier(offset: 20, opacity: 0, scale: 0.8),
                            identity: CustomTransitionModifier(offset: 0, opacity: 1, scale: 1.0)
                        ),
                        removal: .opacity.combined(with: .scale(scale: 0.9))
                    ))
                    .onAppear {
                         // Potential optimization: Track if user has scrolled up manually
                         // If so, maybe don't auto-scroll on new messages unless they are near the bottom.
                         // For now, we always scroll.
                     }
                }
                
                // Typing Indicator
                if viewModel.isTyping {
                    typingIndicatorView()
                }

                // Invisible spacer at the bottom to ensure scrolling past the last message/indicator
                Spacer()
                    .frame(height: 1)
                    .id("bottomAnchor")

            }
            // Add padding within the ScrollView content to keep messages from hitting the very top/bottom edges
            .padding(.vertical)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    @ViewBuilder
    private func typingIndicatorView() -> some View {
        // Determine the sender based on the ViewModel's current mode
        let sender: Sender = (viewModel.currentMode == .yin) ? .yin : .yang // Assuming Sender enum has .yin and .yang

        HStack {
            TypingBubbleView(sender: sender) // <--- Use the determined sender
                .padding(.leading, 5)
            Spacer()
        }
        .padding(.horizontal)
        .id("typingIndicator")
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
    
    @ViewBuilder
    private func inputArea() -> some View {
        VStack(spacing: 0) {
            MessageInputView(
                messageText: $messageText,
                selectedImage: $selectedImage,
                onSend: sendMessage,
                onCameraButtonTapped: handleCameraButtonTapped,
                onPhotoLibraryButtonTapped: handlePhotoLibraryButtonTapped,
                mode: viewModel.currentMode
            )
            .environmentObject(FirebaseManager.shared)
            .padding(.bottom, 0)
            .focused($isFocused)
        }
        .background(Color.clear)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .ignoresSafeArea(.container, edges: .bottom)
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
    
    private func handleCameraButtonTapped() {
        permissionManager.checkCameraPermission()
        if permissionManager.cameraPermissionGranted {
            sourceType = .camera
            isShowingMediaPicker = true
        } else {
            permissionAlertType = "Camera"
            showPermissionAlert = true
        }
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
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty || selectedImage != nil else { return }
        
        // If we're continuing a previous conversation, make sure we track the new messages
        viewModel.continueConversation()
        
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
    
    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool = true) {
        DispatchQueue.main.async { // Ensure it runs on the main thread
            let targetID = viewModel.isTyping ? "typingIndicator" : "bottomAnchor"
            print("Scrolling to \(targetID) (Animated: \(animated))") // Log scrolling action
            if animated {
                withAnimation(.easeOut(duration: 0.25)) { // Slightly slower for smoother feel
                    proxy.scrollTo(targetID, anchor: .bottom)
                }
            } else {
                proxy.scrollTo(targetID, anchor: .bottom)
            }
        }
    }
    
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
    
    // Debounced scroll trigger function
    private func triggerDebouncedScrollToBottom(proxy: ScrollViewProxy) {
        // Invalidate any existing timer to reset the debounce delay
        imageLoadScrollTimer?.invalidate()

        // Schedule a new scroll action after a short delay (e.g., 0.3 seconds)
        // Adjust delay as needed
        imageLoadScrollTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
            print("Debounced scroll triggered by image load.")
            scrollToBottom(proxy: proxy, animated: true) // Ensure animation is true here if desired
        }
    }
}

struct CustomTransitionModifier: ViewModifier {
    let offset: CGFloat
    let opacity: Double
    let scale: CGFloat
    
    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .opacity(opacity)
            .scaleEffect(scale)
            .blur(radius: opacity == 0 ? 5 : 0)
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}

// Helper View for Timestamp Separator
struct TimestampSeparatorView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption) // Smaller font size
            .foregroundColor(.secondary) // Less prominent color
            .padding(.vertical, 10) // Space above and below
            .frame(maxWidth: .infinity) // Center align
    }
}

// Helper function to decide if a separator is needed and format it
func formatTimestampSeparator(current: Date, previous: Date?) -> String? {
    guard let previousDate = previous else {
        // Always show timestamp for the very first message in the list
        return formatDetailedTimestamp(date: current)
    }

    let timeInterval = current.timeIntervalSince(previousDate)

    // Show timestamp separator if more than 1 hour (3600 seconds) has passed
    if timeInterval > 3600 {
        return formatDetailedTimestamp(date: current)
    }

    // Otherwise, don't show a separator
    return nil
}

// Formats the date for the separator view (similar to iMessage)
func formatDetailedTimestamp(date: Date) -> String {
    let formatter = DateFormatter()
    let calendar = Calendar.current

    if calendar.isDateInToday(date) {
        formatter.dateFormat = "h:mm a" // e.g., "10:30 AM"
    } else if calendar.isDateInYesterday(date) {
        formatter.dateFormat = "'Yesterday' h:mm a" // e.g., "Yesterday 2:15 PM"
    } else if let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()), date >= weekAgo {
        // Within the last week
        formatter.dateFormat = "EEEE h:mm a" // e.g., "Monday 9:00 AM"
    } else {
        // Older than a week
        formatter.dateFormat = "MM/dd/yy, h:mm a" // e.g., "11/04/23, 9:30 AM"
    }
    return formatter.string(from: date)
}
