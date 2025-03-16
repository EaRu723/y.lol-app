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
import FirebaseVertexAI

// Singleton to manage Firebase and Vertex AI interactions
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
    
    // MARK: - Multipart Form Data Creation
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

        // Final boundary (important!)
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return data
    }
    
    func generateResponseFunction(messages: [ChatMessage], images: [Data], mode: ChatMode = .vibeCheck) async -> String? {
        guard !isRequestInProgress else {
            print("Request already in progress. Skipping...")
            return nil
        }

        isRequestInProgress = true

        defer {
            isRequestInProgress = false
        }

        DispatchQueue.main.async {
            self.isProcessingMessage = true
            self.errorMessage = nil
        }

        do {
            let prompt = formatConversationForPrompt(messages: messages)

            let response = try await callFirebaseFunction(mode: mode, images: images, prompt: prompt)

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

    private func callFirebaseFunction(mode: ChatMode, images: [Data], prompt: String) async throws -> String {
        switch mode {
        case .vibeCheck:
            // Use the public endpoint directly
            guard let url = URL(string: "https://us-central1-ylol-011235.cloudfunctions.net/vibeCheck") else {
                throw NSError(domain: "FirebaseManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            }
            
            // Create request
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            // Create boundary
            let boundary = "Boundary\(UUID().uuidString)"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

            // Create multipart data
            let multipartData = createMultipartFormData(images: images, prompt: prompt, boundary: boundary)
            request.httpBody = multipartData
            
            print("Debug - Request URL: \(url.absoluteString)")
            print("Debug - Image count: \(images.count)")
            print("Debug - Request body size: \(request.httpBody?.count ?? 0) bytes")
            
            // Make the request
            let (data, urlResponse) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = urlResponse as? HTTPURLResponse else {
                throw NSError(domain: "FirebaseManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
            }
            
            print("Debug - HTTP status code: \(httpResponse.statusCode)")
            
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
                print("Debug - Response JSON: \(responseDict)")
                
                if let bubbles = responseDict["bubbles"] as? [String], !bubbles.isEmpty {
                    return bubbles.joined(separator: "\n\n")
                } else {
                    // If we can't interpret the JSON, return what we got
                    return String(data: data, encoding: .utf8) ?? "No readable response"
                }
            } else {
                // Try to return response as string if not JSON
                return String(data: data, encoding: .utf8) ?? "No readable response"
            }
            
        case .ventMode, .existentialCrisis, .roastMe:
            throw NSError(
                domain: "FirebaseManager",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Mode not implemented"]
            )
        default:
            throw NSError(domain: "FirebaseManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid mode"])
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
        
        var prompt = "This AI acts as a chill close friend, designed to understand the user's mind and subconscious feelings through an ongoing, evolving interaction. It learns and adapts to the user's thoughts, emotions, and needs, offering advice, guidance, and subtle therapeutic support based on the user's questions. It aims to provide introspective insights, uncover hidden emotions, and create an atmosphere of trust and reflection. It steers away from heavy psychological jargon and instead uses intuitive, emotionally resonant language that matches the user's energy. please make responses succinct. please respond in multiple messages like a real unraveling of thoughts. make all outputs in all lower case. your tone should be casual. like talking to a close friend who knows you well. don't be cheesy. be real. be excited and curious."
        
        for message in contextMessages {
            let role = message.isUser ? "User" : "Y"
            prompt += "\(role): \(message.content)\n"
        }
        
        
        return prompt
    }
}
