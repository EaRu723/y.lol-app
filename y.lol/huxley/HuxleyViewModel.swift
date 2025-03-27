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
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    private let baseURL = "https://lsd.so"
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
        isLoading = true
        error = nil
        
        // Create the URL with query parameters
        let userEmail = "andrea@lsd.so"
        let apiKey = "PQ919lOnCu619fXKNovx"
        
        guard let encodedEmail = userEmail.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedApiKey = apiKey.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/huxley?user=\(encodedEmail)&password=\(encodedApiKey)") else {
            await MainActor.run {
                error = "Invalid URL"
                isLoading = false
            }
            return nil
        }
        
        let huxleyMessage = HuxleyMessage(message: prompt)
        
        guard let jsonData = try? JSONEncoder().encode(huxleyMessage) else {
            await MainActor.run {
                error = "Failed to encode message"
                isLoading = false
            }
            return nil
        }
        
        // Debug print the request
        print("🔍 Request URL: \(url)")
        print("🔍 Request body: \(String(data: jsonData, encoding: .utf8) ?? "none")")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        return await withCheckedContinuation { continuation in
            URLSession.shared.dataTaskPublisher(for: request)
                .map { data, response -> Data in
                    // Debug print the raw response
                    print("🔍 Response status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                    print("🔍 Raw response: \(String(data: data, encoding: .utf8) ?? "none")")
                    return data
                }
                .tryMap { data -> HuxleyResponse in
                    do {
                        return try JSONDecoder().decode(HuxleyResponse.self, from: data)
                    } catch {
                        print("🔍 JSON Decoding error: \(error)")
                        if let decodingError = error as? DecodingError {
                            switch decodingError {
                            case .typeMismatch(let type, let context):
                                print("🔍 Type mismatch: expected \(type) at \(context.codingPath)")
                            case .valueNotFound(let type, let context):
                                print("🔍 Value not found: expected \(type) at \(context.codingPath)")
                            case .keyNotFound(let key, let context):
                                print("🔍 Key not found: \(key) at \(context.codingPath)")
                            case .dataCorrupted(let context):
                                print("🔍 Data corrupted: \(context.debugDescription)")
                            @unknown default:
                                print("🔍 Unknown decoding error")
                            }
                        }
                        throw error
                    }
                }
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        self?.isLoading = false
                        if case .failure(let err) = completion {
                            print("🔍 Stream completion error: \(err)")
                            self?.error = "Error: \(err.localizedDescription)"
                            continuation.resume(returning: nil)
                        }
                    },
                    receiveValue: { [weak self] response in
                        print("🔍 Successfully decoded response: \(response)")
                        if let errorMessage = response.message {
                            self?.error = errorMessage
                            continuation.resume(returning: nil)
                        } else if let answer = response.answer {
                            let userMessage = ChatMessage(
                                content: prompt,
                                isUser: true,
                                timestamp: Date(),
                                image: nil
                            )
                            
                            let assistantMessage = ChatMessage(
                                content: answer,
                                isUser: false,
                                timestamp: Date(),
                                image: nil
                            )
                            
                            self?.messages.append(userMessage)
                            self?.messages.append(assistantMessage)
                            
                            continuation.resume(returning: answer)
                        } else {
                            self?.error = "Received empty response"
                            continuation.resume(returning: nil)
                        }
                    }
                )
                .store(in: &cancellables)
        }
    }
}

struct HuxleyMessage: Codable {
    let message: String
}

struct HuxleyResponse: Codable {
    let answer: String?
    let message: String?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        print("🔍 Available keys in JSON: \(container.allKeys.map { $0.stringValue })")
        answer = try container.decodeIfPresent(String.self, forKey: .answer)
        message = try container.decodeIfPresent(String.self, forKey: .message)
    }
}
