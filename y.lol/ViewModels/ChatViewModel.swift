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
    @Published var isTyping: Bool = false
    @Published var errorMessage: String?
    @Published var currentMode: FirebaseManager.ChatMode = .yin {
        didSet {
            if oldValue != currentMode {
                // Force cancel any pending requests before switching modes
                firebaseManager.cancelPendingRequests()
                
                // Generate new conversation with delay to ensure clean separation
                DispatchQueue.main.async {
                    self.startNewConversation()
                }
            }
        }
    }
    @Published var selectedImage: UIImage?
    @Published var isUploadingImage: Bool = false
    @Published var previousConversations: [ChatSession] = []
    @Published var isInitialLoading: Bool = true  // Add loading state
    
    private let firebaseManager = FirebaseManager.shared
    private let hapticService = HapticService()
    private var cancellables = Set<AnyCancellable>()
    private var conversationId = UUID().uuidString
    private let huxleyViewModel = HuxleyViewModel()
    
    // Track messages added in the current session
    private var newSessionMessages: [ChatMessage] = []
    // Track if we're viewing a previous conversation
    private var isViewingPreviousConversation = false
    
    init() {
        // Set up event listeners
        setupObservers()
        
        // Start by loading previous conversations
        // Don't show any messages until we determine what to display
        fetchPreviousConversations()
    }
    
    private func setupObservers() {
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
    }
    
    // Helper to start a fresh conversation
    private func startNewConversation() {
        conversationId = UUID().uuidString
        messages = [
            ChatMessage(
                content: getInitialMessage(for: currentMode),
                isUser: false,
                timestamp: Date(),
                image: nil
            )
        ]
        newSessionMessages = messages
        isViewingPreviousConversation = false
    }
    
    private func fetchPreviousConversations() {
        isInitialLoading = true
        
        FirebaseManager.shared.fetchChatSessions { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let sessions):
                    print("Successfully fetched previous conversations: \(sessions.count) sessions")
                    self.previousConversations = sessions
                    
                    // Check if we have any previous conversations
                    if !sessions.isEmpty {
                        // Sort conversations by timestamp (newest first)
                        let sortedSessions = sessions.sorted(by: { $0.timestamp > $1.timestamp })
                        
                        if let mostRecent = sortedSessions.first, !mostRecent.messages.isEmpty {
                            print("Loading most recent conversation with ID: \(mostRecent.id), containing \(mostRecent.messages.count) messages")
                            self.conversationId = mostRecent.id
                            self.messages = mostRecent.messages
                            self.newSessionMessages = []
                            self.isViewingPreviousConversation = true
                        } else {
                            // If no previous messages, start a new conversation
                            self.startNewConversation()
                        }
                    } else {
                        // If no previous conversations, start a new conversation
                        self.startNewConversation()
                    }
                    
                case .failure(let error):
                    print("Error fetching previous conversations: \(error.localizedDescription)")
                    // In case of error, start a new conversation
                    self.startNewConversation()
                }
                
                // End the loading state
                self.isInitialLoading = false
            }
        }
    }
    
    // Delivers a message bubble with a delay to simulate typing.
    private func deliverMessageWithDelay(_ message: String, isLastMessage: Bool) async {
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.15)) {
                isTyping = true
            }
        }
        
        let baseDelay = Double.random(in: 0.8...1.5)
        let characterDelay = Double(message.count) * 0.005
        let totalDelay = baseDelay + characterDelay
        
        try? await Task.sleep(nanoseconds: UInt64(totalDelay * 1_000_000_000))
        
        // Hide typing indicator.
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.15)) {
                isTyping = false
            }
        }
        
        // Pause a bit longer before showing the message.
        try? await Task.sleep(nanoseconds: UInt64(0.8 * 1_000_000_000))
        
        await MainActor.run {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                let aiMessage = ChatMessage(
                    content: message,
                    isUser: false,
                    timestamp: Date(),
                    image: nil
                )
                messages.append(aiMessage)
                // Add to current session messages
                newSessionMessages.append(aiMessage)
                hapticService.playReceiveFeedback()
            }
        }
        
        if !isLastMessage {
            try? await Task.sleep(nanoseconds: UInt64(0.3 * 1_000_000_000))
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isTyping = true
                }
            }
        }
    }
    
    /// Sends a user message (with an optional image) and gets the AI response.
    func sendMessage(with image: UIImage? = nil) async {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty || image != nil else { return }
        
        // Check if message starts with @huxley
        if trimmedMessage.lowercased().hasPrefix("@huxley") {
            // Remove @huxley from the message
            let huxleyPrompt = trimmedMessage.replacingOccurrences(of: "@huxley", with: "", options: [.caseInsensitive])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            await MainActor.run {
                // Add user message immediately
                messages.append(ChatMessage(
                    content: trimmedMessage,
                    isUser: true,
                    timestamp: Date(),
                    image: nil
                ))
                isThinking = true
            }
            
            // Use Huxley's ViewModel to generate response
            if let response = await huxleyViewModel.generateResponse(prompt: huxleyPrompt) {
                await MainActor.run {
                    // Add the response
                    messages.append(ChatMessage(
                        content: response,
                        isUser: false,
                        timestamp: Date(),
                        image: nil
                    ))
                    isThinking = false
                }
            } else {
                await MainActor.run {
                    // Handle error case
                    messages.append(ChatMessage(
                        content: "Sorry, I encountered an error processing your request.",
                        isUser: false,
                        timestamp: Date(),
                        image: nil
                    ))
                    isThinking = false
                }
            }
            return
        }
        
        hapticService.playSendFeedback()
        
        var currentImageData: [Data] = []
        var imageUrl: String? = nil
        
        // If there's a new image, upload it and prepare its data
        if let image = image {
            await MainActor.run {
                isThinking = true
                isUploadingImage = true // Start showing the spinner
            }
            
            // Upload image and get URL
            await withCheckedContinuation { continuation in
                firebaseManager.uploadImage(image) { result in
                    switch result {
                    case .success(let url):
                        imageUrl = url.absoluteString
                        // Prepare image data for API call
                        if let jpegData = image.jpegData(compressionQuality: 0.7) {
                            currentImageData.append(jpegData)
                        }
                    case .failure(let error):
                        print("Error uploading image: \(error.localizedDescription)")
                    }
                    continuation.resume()
                }
            }
            
            await MainActor.run {
                isUploadingImage = false // Stop showing the spinner
            }
        }
        
        // Create and add the new message
        let newMessage = ChatMessage(
            content: trimmedMessage,
            isUser: true,
            timestamp: Date(),
            imageUrl: imageUrl
        )
        
        await MainActor.run {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                messages.append(newMessage)
                // Add to current session messages
                newSessionMessages.append(newMessage)
                isThinking = true
            }
        }
        
        // Generate AI response with all conversation messages for context
        if let llmResponse = await firebaseManager.generateResponse(
            conversationId: conversationId,
            newMessages: messages,  // Send all messages for context
            currentImageData: currentImageData,
            mode: currentMode
        ) {
            let bubbles = llmResponse.components(separatedBy: "\n\n")
                .filter { !$0.isEmpty }
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            
            // Show typing indicator.
            await MainActor.run { isTyping = true }
            
            // Deliver each bubble with a delay.
            for (index, bubble) in bubbles.enumerated() {
                await deliverMessageWithDelay(bubble, isLastMessage: index == bubbles.count - 1)
            }
            
            // Final cleanup.
            await MainActor.run {
                isTyping = false
                isThinking = false
            }
        } else {
            // In case of an error, show a fallback response.
            await MainActor.run {
                let fallbackMessage = ChatMessage(
                    content: "I seem to be having trouble connecting. Can we pause and reflect for a moment?",
                    isUser: false,
                    timestamp: Date(),
                    image: nil
                )
                
                hapticService.playReceiveFeedback()
                
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    messages.append(fallbackMessage)
                    isThinking = false
                }
            }
        }
    }
    
    /// Returns the initial message for the given chat mode.
    private func getInitialMessage(for mode: FirebaseManager.ChatMode) -> String {
        switch mode {
        case .yin:
            return "what's on your mind?"
        case .yang:
            return "what's good?"
        }
    }
    
    func saveCurrentChatSession() {
        // Only save if there are new user messages in the current session
        guard newSessionMessages.contains(where: { $0.isUser }) else {
            print("No new user messages to save.")
            return
        }
        
        // Create a chat session with ONLY the messages from this session
        let chatSession = ChatSession(id: conversationId, messages: newSessionMessages, timestamp: Date())
        
        firebaseManager.saveChatSession(chatSession: chatSession) { result in
            switch result {
            case .success():
                print("Chat session saved successfully with \(self.newSessionMessages.count) messages.")
            case .failure(let error):
                print("Error saving chat session: \(error.localizedDescription)")
            }
        }
    }
    
    func loadLastConversation() {
        if let lastSession = previousConversations.last {
            print("Loading conversation with ID: \(lastSession.id), containing \(lastSession.messages.count) messages")
            conversationId = lastSession.id
            messages = lastSession.messages
            // Clear new session messages as we're loading an existing conversation
            newSessionMessages = []
            isViewingPreviousConversation = true
        } else {
            print("No previous conversations available to load")
        }
    }
    
    func loadConversation(withId id: String) {
        if let session = previousConversations.first(where: { $0.id == id }) {
            print("Loading selected conversation with ID: \(session.id)")
            conversationId = session.id
            messages = session.messages
            // Clear new session messages as we're loading an existing conversation
            newSessionMessages = []
            isViewingPreviousConversation = true
        }
    }
    
    // Add a method to continue the conversation with new messages
    func continueConversation() {
        // If we're viewing a previous conversation and add new content,
        // we should start tracking new messages
        if isViewingPreviousConversation {
            print("Continuing previous conversation with new messages")
            // Generate a new ID for the continuation
            conversationId = UUID().uuidString
            // We'll keep the messages displayed, but start tracking new ones
            newSessionMessages = []
            isViewingPreviousConversation = false
        }
    }
}
