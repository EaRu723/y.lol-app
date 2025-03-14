//
//  FirebaseManager.swift
//  y.lol
//
//  Created on 3/10/25.
//

import SwiftUI
import FirebaseCore
import FirebaseVertexAI

// Singleton to manage Firebase and Vertex AI interactions
class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    private var vertex: VertexAI?
    private var model: GenerativeModel?  // Changed from VertexGenerativeModel to GenerativeModel
    
    // Message processing state
    @Published var isProcessingMessage = false
    @Published var errorMessage: String?
    
    private init() {
        configureVertexAI()
    }
    
    // Configure Vertex AI (renamed from configureFIrebase to be more accurate)
    private func configureVertexAI() {
        // Initialize Vertex AI (Firebase is already configured in AppDelegate)
        vertex = VertexAI.vertexAI()
        
        // Initialize the generative model with gemini-2.0-flash
        if let vertex = vertex {
            model = vertex.generativeModel(modelName: "gemini-2.0-flash")
        }
    }
    
    // Generate a response based on the conversation history
    func generateResponse(messages: [ChatMessage]) async -> String? {
        guard let model = model else {
            errorMessage = "Model not initialized"
            return nil
        }
        
        DispatchQueue.main.async {
            self.isProcessingMessage = true
            self.errorMessage = nil
        }
        
        do {
            // Create a prompt based on conversation history
            let prompt = formatConversationForPrompt(messages: messages)
            
            // Generate content
            let response = try await model.generateContent(prompt)
            
            DispatchQueue.main.async {
                self.isProcessingMessage = false
            }
            
            return response.text
        } catch {
            DispatchQueue.main.async {
                self.isProcessingMessage = false
                self.errorMessage = error.localizedDescription
            }
            print("Error generating content: \(error)")
            return nil
        }
    }
    
    // Format the conversation history for the AI model
    private func formatConversationForPrompt(messages: [ChatMessage]) -> String {
        // Get last few messages for context (limit to prevent token overflow)
        let contextMessages = messages.suffix(5)
        
        var prompt = "This AI acts as a chill close friend, designed to understand the user's mind and subconscious feelings through an ongoing, evolving interaction. It learns and adapts to the user's thoughts, emotions, and needs, offering advice, guidance, and subtle therapeutic support based on the user's questions. It aims to provide introspective insights, uncover hidden emotions, and create an atmosphere of trust and reflection. It steers away from heavy psychological jargon and instead uses intuitive, emotionally resonant language that matches the user's energy. please make responses succinct. please respond in multiple messages like a real unraveling of thoughts. make all outputs in all lower case. your tone should be casual. like talking to a close friend who knows you well. dont be cheesy. be real. be excited and curious."
        
        for message in contextMessages {
            let role = message.isUser ? "User" : "Y"
            prompt += "\(role): \(message.content)\n"
        }
        
        
        return prompt
    }
}
