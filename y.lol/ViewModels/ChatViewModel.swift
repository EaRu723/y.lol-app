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
    @Published var currentMode: FirebaseManager.ChatMode = .reg {
        didSet {
            if oldValue != currentMode {
                conversationId = UUID().uuidString
                messages = [
                    ChatMessage(content: getInitialMessage(for: currentMode), isUser: false, timestamp: Date())
                ]
            }
        }
    }
    @Published var selectedImage: UIImage?
    
    private let firebaseManager = FirebaseManager.shared
    private let hapticService = HapticService()
    private var cancellables = Set<AnyCancellable>()
    private var conversationId = UUID().uuidString
    
    init() {
        // Subscribe to Firebase manager's state changes
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
        
        // Add initial message
        if messages.isEmpty {
            let initialMessage = ChatMessage(
                content: getInitialMessage(for: currentMode),
                isUser: false,
                timestamp: Date()
            )
            messages.append(initialMessage)
        }
    }
    
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
        
        // Hide typing indicator
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.15)) {
                isTyping = false
            }
        }
        
        // Increased delay between indicator hiding and message appearing
        try? await Task.sleep(nanoseconds: UInt64(0.8 * 1_000_000_000))
        
        await MainActor.run {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                messages.append(ChatMessage(
                    content: message,
                    isUser: false,
                    timestamp: Date()
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
    
    // Send a user message and get AI response
    func sendMessage(with image: UIImage? = nil) async {
        // Trim whitespace and check if message is empty and no image
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty || image != nil else { return }
        
        // Play send haptic feedback
        hapticService.playSendFeedback()
        
        // Convert image to Data if it exists
        var imageData: [Data] = []
        if let image = image, let jpegData = image.jpegData(compressionQuality: 0.7) {
            imageData.append(jpegData)
        }
        
        // Create the user message with text and possible image
        let newMessage = ChatMessage(
            content: trimmedMessage,
            isUser: true,
            timestamp: Date(),
            image: image
        )
        
        // Update UI on main thread
        await MainActor.run {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                messages.append(newMessage)
                isThinking = true
            }
        }
        
        // Generate AI response using Firebase Function
        if let llmResponse = await FirebaseManager.shared.generateResponse(
            conversationId: conversationId,
            messages: messages,
            images: imageData,
            mode: currentMode
        ) {
            let bubbles = llmResponse.components(separatedBy: "\n\n")
                .filter { !$0.isEmpty }
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            
            // Show typing indicator
            await MainActor.run { isTyping = true }
            
            // Deliver each bubble with a delay
            for (index, bubble) in bubbles.enumerated() {
                await deliverMessageWithDelay(bubble, isLastMessage: index == bubbles.count - 1)
            }
            
            // Final cleanup
            await MainActor.run {
                isTyping = false
                isThinking = false
            }
        } else {
            // Handle error with fallback message
            await MainActor.run {
                let fallbackMessage = ChatMessage(
                    content: "I seem to be having trouble connecting. Can we pause and reflect for a moment?",
                    isUser: false,
                    timestamp: Date()
                )
                
                hapticService.playReceiveFeedback()
                
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    messages.append(fallbackMessage)
                    isThinking = false
                }
            }
        }
    }
    
    private func getInitialMessage(for mode: FirebaseManager.ChatMode) -> String {
        switch mode {
        case .reg: return "why are you here?"
        case .vibeCheck: return "let's check the vibes. what's up?"
        case .ventMode: return "need to vent? I'm here."
        case .existentialCrisis: return "feeling existential? let's talk."
        case .roastMe: return "heard you wanted a roast?"
        }
    }
}

