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
    @Published var errorMessage: String?
    @Published var currentMode: FirebaseManager.ChatMode = .vibeCheck
    private let firebaseManager = FirebaseManager.shared
    private let hapticService = HapticService()
    private var cancellables = Set<AnyCancellable>()
    
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
                content: "what's weighing on your mind today?",
                isUser: false,
                timestamp: Date()
            )
            messages.append(initialMessage)
        }
    }
    
    // Send a user message and get AI response
    func sendMessage() async {
        // Trim whitespace and check if message is empty
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        // Play send haptic feedback
        hapticService.playSendFeedback()
        
        let newMessage = ChatMessage(
            content: trimmedMessage,
            isUser: true,
            timestamp: Date()
        )
        
        // Update UI on main thread
        await MainActor.run {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                messages.append(newMessage)
                messageText = ""
                isThinking = true
            }
        }

        // Generate AI response using Firebase Function
        if let response = await firebaseManager.generateResponseFunction(
            messages: messages,
            images: [],
            mode: currentMode
        ) {
            let aiMessage = ChatMessage(
                content: response,
                isUser: false,
                timestamp: Date()
            )
            
            // Play receive haptic feedback and update UI
            await MainActor.run {
                hapticService.playReceiveFeedback()
                
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    messages.append(aiMessage)
                    isThinking = false
                }
            }
        } else {
            // Handle error with fallback message
            await MainActor.run {
                let fallbackMessage = ChatMessage(
                    content: "I seem to be having trouble connecting. Could we pause and reflect for a moment?",
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
}
