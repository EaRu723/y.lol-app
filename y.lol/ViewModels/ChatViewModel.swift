//
//  ChatViewModel.swift
//  y.lol
//
//  Created on 3/10/25.
//

import SwiftUI
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var messageText: String = ""
    @Published var isThinking: Bool = false
    @Published var isTyping: Bool = false
    @Published var errorMessage: String?
    @Published var currentMode: FirebaseManager.ChatMode = .yin {
        didSet {
            if oldValue != currentMode {
                // Force cancel any pending requests before switching modes
                firebaseManager.cancelPendingRequests()
                
                // Generate new conversation with delay to ensure clean separation
                DispatchQueue.main.async {
                    self.conversationId = UUID().uuidString
                    self.messages = [
                        ChatMessage(content: self.getInitialMessage(for: self.currentMode), isUser: false, timestamp: Date(), image: nil)
                    ]
                }
            }
        }
    }
    @Published var selectedImage: UIImage?
    @Published var isUploadingImage: Bool = false
    
    private let firebaseManager = FirebaseManager.shared
    private let hapticService = HapticService()
    private var cancellables = Set<AnyCancellable>()
    private var conversationId = UUID().uuidString
    
    init() {
        // Subscribe to Firebase manager's state changes.
        firebaseManager.$isProcessingMessage
            .receive(on: RunLoop.main)
            .sink { [weak self] isProcessing in
                self?.isThinking = isProcessing
            }
            .store(in: &cancellables)
        
        firebaseManager.$errorMessage
            .receive(on: RunLoop.main)
            .sink { [weak self] error in
                self?.errorMessage = error
            }
            .store(in: &cancellables)
        
        // Add the initial message if none exist.
        if messages.isEmpty {
            let initialMessage = ChatMessage(
                content: getInitialMessage(for: currentMode),
                isUser: false,
                timestamp: Date(),
                image: nil
            )
            messages.append(initialMessage)
        }
    }
    
    // Delivers a message bubble with a delay to simulate typing.
    private func deliverMessageWithDelay(_ message: String, isLastMessage: Bool) async {
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.15)) {
                isTyping = true
            }
        }
        
        let baseDelay = Double.random(in: 0.8...1.5)
        let characterDelay = Double(message.count) * 0.005
        let totalDelay = baseDelay + characterDelay
        
        try? await Task.sleep(nanoseconds: UInt64(totalDelay * 1_000_000_000))
        
        // Hide typing indicator.
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.15)) {
                isTyping = false
            }
        }
        
        // Pause a bit longer before showing the message.
        try? await Task.sleep(nanoseconds: UInt64(0.8 * 1_000_000_000))
        
        await MainActor.run {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                messages.append(ChatMessage(
                    content: message,
                    isUser: false,
                    timestamp: Date(),
                    image: nil
                ))
                hapticService.playReceiveFeedback()
            }
        }
        
        if !isLastMessage {
            try? await Task.sleep(nanoseconds: UInt64(0.3 * 1_000_000_000))
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isTyping = true
                }
            }
        }
    }
    
    /// Sends a user message (with an optional image) and gets the AI response.
    func sendMessage(with image: UIImage? = nil) async {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty || image != nil else { return }
        
        hapticService.playSendFeedback()
        
        var currentImageData: [Data] = []
        var imageUrl: String? = nil
        
        // If there's a new image, upload it and prepare its data
        if let image = image {
            await MainActor.run {
                isThinking = true
                isUploadingImage = true // Start showing the spinner
            }
            
            // Upload image and get URL
            await withCheckedContinuation { continuation in
                firebaseManager.uploadImage(image) { result in
                    switch result {
                    case .success(let url):
                        imageUrl = url.absoluteString
                        // Prepare image data for API call
                        if let jpegData = image.jpegData(compressionQuality: 0.7) {
                            currentImageData.append(jpegData)
                        }
                    case .failure(let error):
                        print("Error uploading image: \(error.localizedDescription)")
                    }
                    continuation.resume()
                }
            }
            
            await MainActor.run {
                isUploadingImage = false // Stop showing the spinner
            }
        }
        
        // Create and add the new message
        let newMessage = ChatMessage(
            content: trimmedMessage,
            isUser: true,
            timestamp: Date(),
            imageUrl: imageUrl
        )
        
        await MainActor.run {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                messages.append(newMessage)
                isThinking = true
            }
        }
        
        // Generate AI response with all conversation images
        if let llmResponse = await firebaseManager.generateResponse(
            conversationId: conversationId,
            newMessages: messages,
            currentImageData: currentImageData,
            mode: currentMode
        ) {
            let bubbles = llmResponse.components(separatedBy: "\n\n")
                .filter { !$0.isEmpty }
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            
            // Show typing indicator.
            await MainActor.run { isTyping = true }
            
            // Deliver each bubble with a delay.
            for (index, bubble) in bubbles.enumerated() {
                await deliverMessageWithDelay(bubble, isLastMessage: index == bubbles.count - 1)
            }
            
            // Final cleanup.
            await MainActor.run {
                isTyping = false
                isThinking = false
            }
        } else {
            // In case of an error, show a fallback response.
            await MainActor.run {
                let fallbackMessage = ChatMessage(
                    content: "I seem to be having trouble connecting. Can we pause and reflect for a moment?",
                    isUser: false,
                    timestamp: Date(),
                    image: nil
                )
                
                hapticService.playReceiveFeedback()
                
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    messages.append(fallbackMessage)
                    isThinking = false
                }
            }
        }
    }
    
    /// Returns the initial message for the given chat mode.
    private func getInitialMessage(for mode: FirebaseManager.ChatMode) -> String {
        switch mode {
        case .yin:
            return "why are you here?"
        case .yang:
            return "what's good?"
        }
    }
}
