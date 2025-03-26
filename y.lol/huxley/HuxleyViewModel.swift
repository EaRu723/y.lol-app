//
//  HuxleyViewModel.swift
//  y.lol
//
//  Created by Andrea Russo on 3/26/25.
//

import Foundation
import SwiftUI
import Combine

class HuxleyViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    private let firebaseManager = FirebaseManager.shared
    private let hapticService = HapticService()
    private var conversationId = UUID().uuidString
    
    init() {
        // Add initial Huxley greeting
        let initialMessage = ChatMessage(
            content: "Hi, I'm Huxley. How can I assist you today?",
            isUser: false,
            timestamp: Date(),
            image: nil
        )
        messages.append(initialMessage)
    }
    
    func generateResponse(prompt: String) async -> String? {
        // Add user message to history
        let userMessage = ChatMessage(
            content: prompt,
            isUser: true,
            timestamp: Date(),
            image: nil
        )
        
        await MainActor.run {
            messages.append(userMessage)
        }
        
        // Generate response using existing Firebase infrastructure
        // but with Huxley-specific modifications
        let response = await firebaseManager.generateResponse(
            conversationId: conversationId,
            newMessages: messages,
            currentImageData: [],
            mode: .yang // or create a specific mode for Huxley
        )
        
        if let response = response {
            let assistantMessage = ChatMessage(
                content: response,
                isUser: false,
                timestamp: Date(),
                image: nil
            )
            
            await MainActor.run {
                messages.append(assistantMessage)
            }
        }
        
        return response
    }
}
