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
import FirebaseFirestore


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
    func generateResponse(
        conversationId: String,
        newMessages: [ChatMessage],
        currentImageData: [Data],
        mode: ChatMode
    ) async -> String? {
        // Log the received message history
        print("FirebaseManager received \(newMessages.count) messages")
        
        // IMPORTANT: Don't fetch additional history from anywhere else
        // Use ONLY the provided newMessages
        
        // Update on main thread
        await MainActor.run {
            self.isProcessingMessage = true
            self.errorMessage = nil
        }
        
        do {
            // ONLY use the image data that was passed in
            // No need to collect additional images from conversation history
            let allImageData = currentImageData
            
            // Extract the last user message as the prompt
            guard let lastUserMessage = newMessages.last(where: { $0.isUser }) else {
                throw NSError(domain: "FirebaseManager", code: 0, 
                              userInfo: [NSLocalizedDescriptionKey: "No user message found"])
            }
            
            // Get the content directly since it's non-optional
            let prompt = lastUserMessage.content
            
            // Use messages excluding the last user message as history
            let historyMessages = newMessages.filter { $0.id != lastUserMessage.id }
            
            // Convert conversation history to JSON
            let historyJSON = createHistoryJSON(from: historyMessages)
            
            // Call the Firebase function with ONLY the current image data
            let response = try await callFirebaseFunction(
                mode: mode,
                images: allImageData,  // All images from the conversation
                prompt: prompt,
                historyJSON: historyJSON
            )
            
            // Cache the assistant's response if available.
            if let responseText = response {
                let assistantMessage = ChatMessage(
                    content: responseText,
                    isUser: false,
                    timestamp: Date(),
                    media: nil  // No media for assistant messages initially
                )
                updateConversationCache(conversationId: conversationId, messages: [assistantMessage])
            }
            
            return response
        } catch {
            // Update on main thread
            await MainActor.run {
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
            let role = message.isUser ? "user" : "assistant"
            var contentDict: [String: Any] = [
                "role": role
            ]
            
            var parts: [[String: Any]] = [["text": message.content]]
            
            // For user messages that had images, add an inline text reference
            if message.isUser, 
               let mediaItems = message.media,
               mediaItems.contains(where: { $0.type == .image }) {
                parts.append(["text": "[Image]"])
            }
            
            contentDict["parts"] = parts
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
            if let bubbles = responseDict["bubbles"] as? [String] {
                if bubbles.isEmpty {
                    // Return empty string for empty bubbles array
                    return ""
                }
                
                // Filter out any empty bubbles or whitespace-only bubbles
                let filteredBubbles = bubbles.filter { 
                    let trimmed = $0.trimmingCharacters(in: .whitespacesAndNewlines)
                    return !trimmed.isEmpty
                }
                
                // If all bubbles were empty/whitespace, return empty string
                if filteredBubbles.isEmpty {
                    return ""
                }
                
                return filteredBubbles.joined(separator: "\n\n")
            } else if let result = responseDict["result"] as? String {
                let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? "" : trimmed
            } else if let text = responseDict["text"] as? String {
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? "" : trimmed
            } else {
                // Try to parse the raw response
                let rawResponse = String(data: data, encoding: .utf8) ?? ""
                let trimmed = rawResponse.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Check if the response is just whitespace/control characters
                let nonWhitespace = trimmed.components(separatedBy: .whitespacesAndNewlines).joined()
                if nonWhitespace.isEmpty || nonWhitespace == "{\"bubbles\":[]}" {
                    return ""
                }
                
                return trimmed
            }
        } else {
            // Handle the case where the response isn't valid JSON at all
            let rawResponse = String(data: data, encoding: .utf8) ?? ""
            let trimmed = rawResponse.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check if it's just whitespace
            if trimmed.isEmpty {
                return ""
            }
            
            return trimmed
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
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            completion(.failure(NSError(domain: "ImageConversion", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])))
            return
        }
        
        // Get the current user's UID
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        // Create a reference to the storage location
        let storageRef = Storage.storage().reference().child("user_images/\(uid)/\(UUID().uuidString).jpg")
        
        // Upload the image data
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Get the download URL
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url))
                }
            }
        }
    }
    
    /// Returns the appropriate Firebase function endpoint based on the chat mode.
    private func getFunctionEndpoint(for mode: ChatMode) -> String {
//        let baseUrl = "https://us-central1-ylol-011235.cloudfunctions.net"
        let baseUrl = "http://127.0.0.1:5001/ylol-011235/us-central1"
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
    
    // Helper function to load image data from URL
    private func loadImageFromURL(_ urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            print("Error loading image from URL: \(error)")
            return nil
        }
    }
    
    func saveChatSession(chatSession: ChatSession, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        let db = Firestore.firestore()
        let chatRef = db.collection("users").document(uid).collection("conversations").document(chatSession.id)
        
        // Set persistence to enable offline data
        let settings = db.settings
        settings.isPersistenceEnabled = true
        db.settings = settings
        
        do {
            let data = try JSONEncoder().encode(chatSession)
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            
            // Use merge: true to prevent overwriting existing data
            chatRef.setData(json as! [String: Any], merge: true) { error in
                if let error = error {
                    // Log the error but don't treat network connectivity errors as failures
                    if (error as NSError).domain == "FIRFirestoreErrorDomain" && 
                       (error as NSError).code == 8 { // Unavailable error code
                        print("Network unavailable, data will be synced when connection is restored")
                        completion(.success(())) // Consider it a success as data will be synced later
                    } else {
                        completion(.failure(error))
                    }
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func fetchChatSessions(completion: @escaping (Result<[ChatSession], Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(uid).collection("conversations").getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else if let snapshot = snapshot {
                do {
                    var chatSessions: [ChatSession] = []
                    
                    for document in snapshot.documents {
                        do {
                            // Try using Firestore's built-in deserialization
                            if let chatSession = try? document.data(as: ChatSession.self) {
                                print("Successfully decoded chat session with ID: \(chatSession.id)")
                                chatSessions.append(chatSession)
                            } else {
                                // Manual fallback if automatic decoding fails
                                print("Fallback to manual decoding for document: \(document.documentID)")
                                let data = document.data()
                                let id = document.documentID
                                
                                // Extract timestamp
                                var timestamp = Date()
                                if let timestampValue = data["timestamp"] as? TimeInterval {
                                    timestamp = Date(timeIntervalSince1970: timestampValue)
                                } else if let firestoreTimestamp = data["timestamp"] as? Timestamp {
                                    timestamp = firestoreTimestamp.dateValue()
                                }
                                
                                // Extract and convert messages
                                var messages: [ChatMessage] = []
                                if let messagesData = data["messages"] as? [[String: Any]] {
                                    for messageData in messagesData {
                                        // Extract basic message fields
                                        let content = messageData["content"] as? String ?? ""
                                        let isUser = messageData["isUser"] as? Bool ?? false
                                        
                                        // Handle timestamp
                                        var messageTimestamp = Date()
                                        if let timestampDouble = messageData["timestamp"] as? TimeInterval {
                                            messageTimestamp = Date(timeIntervalSince1970: timestampDouble)
                                        } else if let firestoreTimestamp = messageData["timestamp"] as? Timestamp {
                                            messageTimestamp = firestoreTimestamp.dateValue()
                                        }
                                        
                                        // Handle media if present
                                        var media: [MediaContent]? = nil
                                        if let mediaData = messageData["media"] as? [[String: Any]], !mediaData.isEmpty {
                                            media = mediaData.compactMap { mediaItem -> MediaContent? in
                                                guard 
                                                    let id = mediaItem["id"] as? String,
                                                    let url = mediaItem["url"] as? String,
                                                    let timestampValue = mediaItem["timestamp"] as? TimeInterval
                                                else { return nil }
                                                
                                                // Assume image type as default
                                                return MediaContent(
                                                    id: id,
                                                    type: .image,
                                                    url: url,
                                                    metadata: nil,
                                                    timestamp: timestampValue
                                                )
                                            }
                                        }
                                        
                                        // Create the message with proper ID
                                        var message = ChatMessage(
                                            content: content, 
                                            isUser: isUser, 
                                            timestamp: messageTimestamp,
                                            media: media
                                        )
                                        
                                        // Set the ID if present
                                        if let idString = messageData["id"] as? String, 
                                           let uuid = UUID(uuidString: idString) {
                                            message.id = uuid
                                        }
                                        
                                        messages.append(message)
                                    }
                                }
                                
                                // Extract the chat mode if available, default to .yin if not present
                                let modeString = data["chatMode"] as? String ?? "yin"
                                let chatMode: FirebaseManager.ChatMode = modeString == "yang" ? .yang : .yin
                                
                                print("Manually decoded \(messages.count) messages for session \(id)")
                                let chatSession = ChatSession(
                                    id: id, 
                                    messages: messages, 
                                    timestamp: timestamp,
                                    chatMode: chatMode
                                )
                                chatSessions.append(chatSession)
                            }
                        } catch {
                            print("Error decoding chat session from document \(document.documentID): \(error)")
                        }
                    }
                    
                    // Sort sessions by timestamp, newest first
                    chatSessions.sort { $0.timestamp > $1.timestamp }
                    
                    print("Successfully retrieved \(chatSessions.count) chat sessions")
                    completion(.success(chatSessions))
                } catch {
                    print("Error parsing chat sessions: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }

    
}

class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {
        // Set cache limits if needed
        cache.countLimit = 100 // Maximum number of images
        cache.totalCostLimit = 1024 * 1024 * 100 // 100 MB
    }
    
    func set(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
    
    func get(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func remove(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
    
    func clear() {
        cache.removeAllObjects()
    }
}

struct CachedAsyncImage: View {
    let url: URL?
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
            } else {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .task {
                                // Cache the loaded image asynchronously
                                if let url = url {
                                    do {
                                        let (data, _) = try await URLSession.shared.data(from: url)
                                        if let uiImage = UIImage(data: data) {
                                            ImageCache.shared.set(uiImage, forKey: url.absoluteString)
                                        }
                                    } catch {
                                        print("Error caching image: \(error)")
                                    }
                                }
                            }
                    case .empty:
                        ProgressView()
                    case .failure(_):
                        Text("Failed to load")
                    @unknown default:
                        EmptyView()
                    }
                }
                .onAppear {
                    // Check cache first
                    if let url = url,
                       let cachedImage = ImageCache.shared.get(forKey: url.absoluteString) {
                        self.image = cachedImage
                    }
                }
            }
        }
    }
}
