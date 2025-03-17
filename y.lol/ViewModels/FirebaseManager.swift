//
//  FirebaseManager.swift
//  y.lol
//
//  Created on 3/10/25.
//
import SwiftUI
import FirebaseCore
import FirebaseFunctions
import FirebaseAuth

class FirebaseManager: ObservableObject {
    enum ChatMode {
        case reg
        case vibeCheck
        case ventMode
        case existentialCrisis
        case roastMe
    }

    private var isRequestInProgress = false
    static let shared = FirebaseManager()
    
    // Message processing state
    @Published var isProcessingMessage = false
    @Published var errorMessage: String?
    
    // Conversation history cache
    private var conversationCache: [String: [ChatMessage]] = [:]
    private let maxContextMessages = 10
    
    // Main function to generate responses (with or without images)
    func generateResponse(conversationId: String, messages: [ChatMessage], images: [Data] = [], mode: ChatMode = .reg) async -> String? {
        guard !isRequestInProgress else {
            print("Request already in progress. Skipping...")
            return nil
        }

        isRequestInProgress = true
        defer { isRequestInProgress = false }

        DispatchQueue.main.async {
            self.isProcessingMessage = true
            self.errorMessage = nil
        }

        do {
            // Update conversation cache
            updateConversationCache(conversationId: conversationId, messages: messages)
            
            // Get conversation history
            let contextMessages = getContextMessages(conversationId: conversationId)
            
            // Format the prompt with system instructions and conversation history
            let prompt = formatConversationForPrompt(messages: contextMessages)
            
            // Call the appropriate Firebase function based on mode
            let response = try await callFirebaseFunction(mode: mode, images: images, prompt: prompt)
            
            // Cache the assistant's response
            if let responseText = response {
                let assistantMessage = ChatMessage(content: responseText, isUser: false, timestamp: Date())
                updateConversationCache(conversationId: conversationId, messages: [assistantMessage])
            }

            DispatchQueue.main.async {
                self.isProcessingMessage = false
            }

            return response
        } catch {
            DispatchQueue.main.async {
                self.isProcessingMessage = false
                self.errorMessage = error.localizedDescription
            }
            print("Error generating content: \(error)")
            return nil
        }
    }

    // Update the conversation cache
    private func updateConversationCache(conversationId: String, messages: [ChatMessage]) {
        if conversationCache[conversationId] == nil {
            conversationCache[conversationId] = []
        }
        
        for message in messages {
            let exists = conversationCache[conversationId]?.contains{$0.id == message.id} ?? false
            if !exists {
                conversationCache[conversationId]?.append(contentsOf: messages)
            }
        }
        
        // Trim if needed
        if let cachedMessages = conversationCache[conversationId], cachedMessages.count > maxContextMessages * 2 {
            conversationCache[conversationId] = Array(cachedMessages.suffix(maxContextMessages))
        }
    }
    
    // Get context messages for a conversation
    private func getContextMessages(conversationId: String) -> [ChatMessage] {
        return conversationCache[conversationId]?.suffix(maxContextMessages) ?? []
    }
    
    // Format conversation into a prompt
    private func formatConversationForPrompt(messages: [ChatMessage]) -> String {
        var prompt = "Conversation history:\n"
        
        for message in messages {
            let role = message.isUser ? "User" : "Y"
            prompt += "\(role): \(message.content)\n"
        }
        
        return prompt
    }

    // Call Firebase Function based on the mode
    private func callFirebaseFunction(mode: ChatMode, images: [Data], prompt: String) async throws -> String? {
        // Determine the endpoint based on the mode
        let endpoint = getFunctionEndpoint(for: mode)
        
        guard let url = URL(string: endpoint) else {
            throw NSError(domain: "FirebaseManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Use multipart form data for function HTTP requests
        let boundary = "Boundary\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = createMultipartFormData(images: images, prompt: prompt, boundary: boundary)
        
        // Make the request
        let (data, urlResponse) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw NSError(domain: "FirebaseManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
        }
        
        // Handle error response codes
        if httpResponse.statusCode >= 400 {
            print("Debug - Error response: \(String(data: data, encoding: .utf8) ?? "No readable response")")
            throw NSError(
                domain: "FirebaseManager",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "Server returned error code \(httpResponse.statusCode)"]
            )
        }
        
        // Parse the JSON response
        if let responseDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            // First try to get bubbles
            if let bubbles = responseDict["bubbles"] as? [String], !bubbles.isEmpty {
                return bubbles.joined(separator: "\n\n")
            }
            // Then try to get result
            else if let result = responseDict["result"] as? String {
                return result
            }
            // Then try to get text
            else if let text = responseDict["text"] as? String {
                return text
            }
            // Return the raw response as last resort
            else {
                return String(data: data, encoding: .utf8) ?? "No readable response"
            }
        } else {
            // Try to return response as string if not JSON
            return String(data: data, encoding: .utf8) ?? "No readable response"
        }
    }
    
    // Get the appropriate endpoint for each mode
    private func getFunctionEndpoint(for mode: ChatMode) -> String {
        let baseUrl = "https://us-central1-ylol-011235.cloudfunctions.net"
        
        switch mode {
        case .vibeCheck:
            return "\(baseUrl)/vibeCheck"
        case .ventMode:
            return "\(baseUrl)/ventMode" // This would need to be implemented on Firebase
        case .existentialCrisis:
            return "\(baseUrl)/existentialCrisis" // This would need to be implemented on Firebase
        case .roastMe:
            return "\(baseUrl)/roastMe" // This would need to be implemented on Firebase
        case .reg:
            return "\(baseUrl)/baseConversation"
        }
    }
    
    // Multipart form data creation
    private func createMultipartFormData(images: [Data], prompt: String, boundary: String) -> Data {
        var data = Data()

        // Add prompt
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
        data.append(prompt.data(using: .utf8)!)
        data.append("\r\n".data(using: .utf8)!)

        // Add images
        for (index, imageData) in images.enumerated() {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"images\"; filename=\"image\(index).jpg\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            data.append(imageData)
            data.append("\r\n".data(using: .utf8)!)
        }

        // Final boundary
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return data
    }
}
