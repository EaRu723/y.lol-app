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
import FirebaseStorage

/// FirebaseManager that sends messages to Firebase functions.
class FirebaseManager: ObservableObject {
    enum ChatMode {
        case yin
        case yang
    }
    
    private var isRequestInProgress = false
    static let shared = FirebaseManager()
    
    // Message processing state
    @Published var isProcessingMessage = false
    @Published var errorMessage: String?
    
    // Conversation history cache: [conversationId: [ChatMessage]]
    private var conversationCache: [String: [ChatMessage]] = [:]
    
    // Add this property
    private let authManager = AuthenticationManager.shared
    
    // MARK: - Public API
    
    /// Generates a response given the conversationId, a new message, and optional images.
    func generateResponse(conversationId: String, newMessages: [ChatMessage], images: [Data] = [], mode: ChatMode = .yin) async -> String? {
        // Check for token errors but don't immediately abort
        if authManager.hasTokenError {
            // Try to refresh the token first
            let refreshSucceeded = await authManager.validateToken()
            if !refreshSucceeded {
                print("Token refresh failed, aborting request")
                return nil
            }
            print("Token refreshed successfully, continuing with request")
        }
        
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
            // Update the conversation cache with the new messages.
            updateConversationCache(conversationId: conversationId, messages: newMessages)
            
            // Separate out the new user prompt and prior history.
            guard let (prompt, historyMessages) = getHistoryAndPrompt(conversationId: conversationId) else {
                throw NSError(domain: "FirebaseManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No new user message found"])
            }
            
            // Convert conversation history (without the new prompt) to JSON
            let historyJSON = createHistoryJSON(from: historyMessages)
            
            // Call the appropriate Firebase function (yin or yang)
            let response = try await callFirebaseFunction(mode: mode, images: images, prompt: prompt, historyJSON: historyJSON)
            
            // Cache the assistant's response if available.
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
    
    // MARK: - Conversation History Management
    
    /// Updates the conversation cache with new messages.
    private func updateConversationCache(conversationId: String, messages: [ChatMessage]) {
        if conversationCache[conversationId] == nil {
            conversationCache[conversationId] = []
        }
        
        // Append each new message if it does not already exist.
        for message in messages {
            if conversationCache[conversationId]?.contains(where: { $0.id == message.id }) == false {
                conversationCache[conversationId]?.append(message)
            }
        }
        
        // Trim history if it exceeds twice the max context messages.
        if let cachedMessages = conversationCache[conversationId] {
            conversationCache[conversationId] = Array(cachedMessages)
        }
    }
    
    /// Separates the most recent user message (to be sent as prompt) from the conversation history.
    /// The conversation history is filtered to remove the initial visual-only model message.
    private func getHistoryAndPrompt(conversationId: String) -> (String, [ChatMessage])? {
        guard let messages = conversationCache[conversationId], !messages.isEmpty else {
            return nil
        }
        // Assume the last message is the new user prompt.
        let lastMessage = messages.last!
        guard lastMessage.isUser else {
            return nil
        }
        let prompt = lastMessage.content
        // Get the history excluding the latest user message.
        var history = Array(messages.dropLast())
        // Remove the first message if it's from the model (i.e. the visual-only initial message).
        if let first = history.first, !first.isUser {
            history.removeFirst()
        }
        return (prompt, history)
    }
    
    /// Converts an array of ChatMessage into a JSON string representing an array of Content objects.
    /// Each Content object has:
    ///    - role: "user" or "model"
    ///    - parts: an array containing one TextPart with the message content.
    private func createHistoryJSON(from messages: [ChatMessage]) -> String {
        var contents: [[String: Any]] = []
        for message in messages {
            let role = message.isUser ? "user" : "model"
            let contentDict: [String: Any] = [
                "role": role,
                "parts": [
                    ["text": message.content]
                ]
            ]
            contents.append(contentDict)
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: contents, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return "[]"
        }
        return jsonString
    }
    
    // MARK: - Firebase Function Request
    
    /// Calls the Firebase function endpoint (based on the chat mode) using multipart form data.
    /// The request includes the new prompt, the conversation history JSON, and any image files.
    private func callFirebaseFunction(mode: ChatMode, images: [Data], prompt: String, historyJSON: String) async throws -> String? {
        do {
            return try await actualCallImplementation(mode: mode, images: images, prompt: prompt, historyJSON: historyJSON)
        } catch let error as NSError {
            // Check if this is an auth error (401/403)
            if error.domain == "FirebaseManager" && (error.code == 401 || error.code == 403) {
                // Try to refresh token and retry
                return try await authManager.refreshTokenAndRetry {
                    try await self.actualCallImplementation(mode: mode, images: images, prompt: prompt, historyJSON: historyJSON)
                }
            } else {
                // For non-auth errors, just re-throw
                throw error
            }
        }
    }
    
    // Extract the actual implementation to a separate method for reuse in retry
    private func actualCallImplementation(mode: ChatMode, images: [Data], prompt: String, historyJSON: String) async throws -> String {
        let endpoint = getFunctionEndpoint(for: mode)
        guard let url = URL(string: endpoint) else {
            throw NSError(domain: "FirebaseManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Include auth ID token for authenticated request
        guard let idToken = AuthenticationManager.shared.idToken else {
            throw NSError(domain: "FirebaseManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Missing ID Token for authentication"])
        }
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        
        // Create multipart form data with the new prompt, history JSON, and images.
        let boundary = "Boundary\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = createMultipartFormData(prompt: prompt, historyJSON: historyJSON, images: images, boundary: boundary)
        
        let (data, urlResponse) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw NSError(domain: "FirebaseManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
        }
        
        // If error code received, throw error.
        if httpResponse.statusCode >= 400 {
            print("Debug - Error response: \(String(data: data, encoding: .utf8) ?? "No readable response")")
            // Check for auth errors specifically
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                // Try to refresh the token before failing
                do {
                    return try await authManager.refreshTokenAndRetry {
                        // Retry the same request after token refresh
                        // Use parameters from the current function context instead
                        return try await self.actualCallImplementation(
                            mode: mode, 
                            images: images, 
                            prompt: prompt, 
                            historyJSON: historyJSON
                        )
                    }
                } catch {
                    // Only set token error if refresh and retry failed
                    await MainActor.run {
                        AuthenticationManager.shared.hasTokenError = true
                    }
                    throw error
                }
            }

            // Parse error response if possible
            if let errorText = String(data: data, encoding: .utf8) {
                throw NSError(domain: "FirebaseManager", code: 0, userInfo: [NSLocalizedDescriptionKey: errorText])
            } else {
                throw NSError(domain: "FirebaseManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])
            }
        }
        
        // Try to parse the JSON response.
        if let responseDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            // Prefer "bubbles" field if present.
            if let bubbles = responseDict["bubbles"] as? [String], !bubbles.isEmpty {
                return bubbles.joined(separator: "\n\n")
            } else if let result = responseDict["result"] as? String {
                return result
            } else if let text = responseDict["text"] as? String {
                return text
            } else {
                return String(data: data, encoding: .utf8) ?? "No readable response"
            }
        } else {
            return String(data: data, encoding: .utf8) ?? "No readable response"
        }
    }
    
    /// Creates the multipart form data payload.
    /// Includes:
    ///  - "prompt" field (new user message)
    ///  - "history" field (JSON string of conversation history)
    ///  - Each image under the "images" field.
    private func createMultipartFormData(prompt: String, historyJSON: String, images: [Data], boundary: String) -> Data {
        var data = Data()
        
        // Append the prompt field.
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
        data.append(prompt.data(using: .utf8)!)
        data.append("\r\n".data(using: .utf8)!)
        
        // Append the history field.
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"history\"\r\n\r\n".data(using: .utf8)!)
        data.append(historyJSON.data(using: .utf8)!)
        data.append("\r\n".data(using: .utf8)!)
        
        // Append each image.
        for (index, imageData) in images.enumerated() {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"images\"; filename=\"image\(index).jpg\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            data.append(imageData)
            data.append("\r\n".data(using: .utf8)!)
        }
        
        // Append the final boundary.
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return data
    }
    
    /// Uploads an image to Firebase Cloud Storage and return the URL
    func uploadImage(_ image: UIImage, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "FirebaseManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to convert image to data."])))
            return
        }
        
        let storageRef = Storage.storage().reference().child("images/\(UUID().uuidString).jpg")
        
        let uploadTask = storageRef.putData(imageData, metadata: nil)
        
        // Observe success
        uploadTask.observe(.success) {_ in
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url))
                }
            }
        }
        
        // Observe failure
        uploadTask.observe(.failure) { snapshot in
            if let error = snapshot.error {
                completion(.failure(error))
            }
        }
    }
    
    /// Returns the appropriate Firebase function endpoint based on the chat mode.
    private func getFunctionEndpoint(for mode: ChatMode) -> String {
        let baseUrl = "https://us-central1-ylol-011235.cloudfunctions.net"
//        let baseUrl = "http://127.0.0.1:5001/ylol-011235/us-central1"
        switch mode {
        case .yin:
            return "\(baseUrl)/yin"
        case .yang:
            return "\(baseUrl)/yang"
        }
    }
    
    func cancelPendingRequests() {
        isRequestInProgress = false
    }
}
