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
                isThinking = true
            }
        }
        
        // Generate AI response using Firebase Function
        if let llmResponse = await FirebaseManager.shared.generateResponse(
            conversationId: conversationId, // Use a unique ID for each conversation
            messages: messages,
            images: [], // TODO: implement file upload, and include them here
            mode: currentMode
        )
        {
            let aiMessage = ChatMessage(
                content: llmResponse,
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
    
    func sendImageMessage(_ image: UIImage) {
        // Play send haptic feedback
        hapticService.playSendFeedback()
        
        // Create a message with the image
        let newMessage = ChatMessage(
            content: "",
            isUser: true,
            timestamp: Date(),
            image: image
        )
        
        // Add the message to the messages array
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            messages.append(newMessage)
            isThinking = true
        }
        
        // Here you would typically upload the image to your backend
        // For now, we'll just add it to the local messages and simulate a response
        
        // Simulate AI response after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isThinking = false
            
            let aiResponse = ChatMessage(
                content: "I received your image! It looks interesting.",
                isUser: false,
                timestamp: Date()
            )
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                self.messages.append(aiResponse)
            }
        }
        
        // TODO: In the future, you'll want to actually send the image to your backend
        // and get a real response, similar to how text messages are handled
    }
    
    private func getInitialMessage(for mode: FirebaseManager.ChatMode) -> String {
        switch mode {
        case .reg: return "what's weighing on your mind today?"
        case .vibeCheck: return "let's check the vibes. what's up?"
        case .ventMode: return "need to vent? I'm here."
        case .existentialCrisis: return "feeling existential? let's talk."
        case .roastMe: return "heard you wanted a roast?"
        }
    }
}


// TODO:
// - Add image processing
//@Published var selectedImage: UIImage?
//
//func sendImageMessage(_ image: UIImage) {
//    // Create a message with the image
//    let newMessage = Message(
//        id: UUID().uuidString,
//        text: "",
//        sender: .user,
//        timestamp: Date(),
//        image: image
//    )
//    
//    // Add the message to the messages array
//    messages.append(newMessage)
//    
//    // Here you would typically upload the image to your backend
//    // For now, we'll just add it to the local messages
//    
//    // Optional: You can also trigger an AI response to the image
//    isThinking = true
//    
//    // Simulate AI response after a delay
//    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//        self.isThinking = false
//        
//        let aiResponse = Message(
//            id: UUID().uuidString,
//            text: "I received your image! It looks interesting.",
//            sender: .ai,
//            timestamp: Date()
//        )
//        
//        self.messages.append(aiResponse)
//    }
//}
