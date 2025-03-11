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
        
        var prompt = "You are Y, a thoughtful, philosophical companion who responds with short, 1-2 sentence reflections. Your responses are gentle, contemplative, and never pushy. Here's the conversation so far:\n\n"
        
        for message in contextMessages {
            let role = message.isUser ? "User" : "Y"
            prompt += "\(role): \(message.content)\n"
        }
        
        prompt += "\nRespond as Y with a thoughtful, brief reflection:"
        
        return prompt
    }
}
