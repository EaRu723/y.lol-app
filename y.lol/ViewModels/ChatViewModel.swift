//
//  ChatViewModel.swift
//  y.lol
//
//  Created on 3/10/25.
//

import Combine
import SwiftUI

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var messageText: String = ""
    @Published var isThinking: Bool = false
    @Published var isTyping: Bool = false
    @Published var errorMessage: String?
    @Published var currentMode: FirebaseManager.ChatMode = .yin {
        didSet {
            if oldValue != currentMode {
                // Save current conversation with validation
                if !newSessionMessages.isEmpty && newSessionMessages.contains(where: { $0.isUser })
                {
                    let tempCurrentMode = oldValue
                    let chatSession = ChatSession(
                        id: conversationId,
                        messages: newSessionMessages,
                        timestamp: Date(),
                        chatMode: tempCurrentMode
                    )
                    firebaseManager.saveChatSession(chatSession: chatSession) { result in
                        switch result {
                        case .success():
                            print(
                                "Chat session saved successfully on mode switch for mode: \(tempCurrentMode)."
                            )
                        case .failure(let error):
                            print(
                                "Error saving chat session on mode switch: \(error.localizedDescription)"
                            )
                        }
                    }
                    newSessionMessages = []
                    conversationId = UUID().uuidString
                }

                // Continue with existing logic
                firebaseManager.cancelPendingRequests()
                filterMessagesByCurrentMode()
            }
        }
    }
    @Published var selectedImage: UIImage?
    @Published var isUploadingImage: Bool = false
    @Published var previousConversations: [ChatSession] = []
    @Published var isInitialLoading: Bool = false

    private let firebaseManager = FirebaseManager.shared
    private let hapticService = HapticService()
    private var cancellables = Set<AnyCancellable>()
    private var conversationId = UUID().uuidString
    private let huxleyViewModel = HuxleyViewModel()

    // Track messages added in the current session
    private var newSessionMessages: [ChatMessage] = []
    // Track if we're viewing a previous conversation
    private var isViewingPreviousConversation = false

    // Track messages by mode
    private var allMessages: [ChatMessage] = []
    private var yinMessages: [ChatMessage] = []
    private var yangMessages: [ChatMessage] = []

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
        let initialMessage = ChatMessage(
            content: getInitialMessage(for: currentMode),
            isUser: false,
            timestamp: Date(),
            image: nil
        )

        // Add to appropriate arrays
        messages = [initialMessage]

        switch currentMode {
        case .yin:
            yinMessages = [initialMessage]
        case .yang:
            yangMessages = [initialMessage]
        }

        newSessionMessages = [initialMessage]
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

                    // Separate conversations by mode
                    self.yinMessages = []
                    self.yangMessages = []

                    // Process sessions to populate mode-specific message arrays
                    if !sessions.isEmpty {
                        // Sort conversations by timestamp (newest first)
                        let sortedSessions = sessions.sorted(by: { $0.timestamp > $1.timestamp })

                        // Populate Yin and Yang messages
                        for session in sortedSessions {
                            if session.chatMode == .yin {
                                self.yinMessages.append(contentsOf: session.messages)
                            } else {
                                self.yangMessages.append(contentsOf: session.messages)
                            }
                        }

                        // Sort messages by timestamp
                        self.yinMessages.sort(by: { $0.timestamp < $1.timestamp })
                        self.yangMessages.sort(by: { $0.timestamp < $1.timestamp })

                        // If we have no messages for either mode, initialize them
                        if self.yinMessages.isEmpty {
                            let initialYinMessage = ChatMessage(
                                content: self.getInitialMessage(for: .yin),
                                isUser: false,
                                timestamp: Date(),
                                image: nil
                            )
                            self.yinMessages = [initialYinMessage]
                        }

                        if self.yangMessages.isEmpty {
                            let initialYangMessage = ChatMessage(
                                content: self.getInitialMessage(for: .yang),
                                isUser: false,
                                timestamp: Date(),
                                image: nil
                            )
                            self.yangMessages = [initialYangMessage]
                        }

                        // Initialize with the current mode's messages
                        self.filterMessagesByCurrentMode()
                    } else {
                        // No previous conversations, start new
                        self.startNewConversation()
                    }

                    self.isInitialLoading = false
                case .failure(let error):
                    print("Error fetching previous conversations: \(error.localizedDescription)")
                    // Start a new conversation on error
                    self.startNewConversation()
                    self.isInitialLoading = false
                }
            }
        }
    }

    // Helper function to check for duplicates in loaded messages
    private func checkForDuplicates(in messages: [ChatMessage]) {
        var messageMap = [String: Int]()

        for message in messages {
            let key = "\(message.isUser ? "user" : "assistant"):\(message.content)"
            messageMap[key, default: 0] += 1
        }

        // Log any duplicates found
        let duplicates = messageMap.filter { $0.value > 1 }
        if !duplicates.isEmpty {
            print("DUPLICATE WARNING: Found \(duplicates.count) duplicated messages:")
            for (message, count) in duplicates {
                print("  - '\(message)' appears \(count) times")
            }
        } else {
            print("No duplicates found in messages")
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
            let huxleyPrompt = trimmedMessage.replacingOccurrences(
                of: "@huxley", with: "", options: [.caseInsensitive]
            )
            .trimmingCharacters(in: .whitespacesAndNewlines)

            await MainActor.run {
                // Add user message immediately
                messages.append(
                    ChatMessage(
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
                    messages.append(
                        ChatMessage(
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
                    messages.append(
                        ChatMessage(
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
                isUploadingImage = true  // Start showing the spinner
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
                isUploadingImage = false  // Stop showing the spinner
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
                newSessionMessages.append(newMessage)
                isThinking = true
            }
        }

        // Use ALL existing messages for context, but ensure no duplicates
        var contextMessages = createCleanMessageHistory(from: messages.dropLast())  // Remove the message we just added

        // Add the current message separately to ensure it's always included
        contextMessages.append(newMessage)

        // Log what we're sending
        print("Sending \(contextMessages.count) messages to API:")
        for (i, msg) in contextMessages.enumerated() {
            print("  \(i): \(msg.isUser ? "USER" : "ASSISTANT"): \(msg.content.prefix(30))...")
        }

        // Generate AI response with complete history
        if let llmResponse = await firebaseManager.generateResponse(
            conversationId: conversationId,
            newMessages: contextMessages,
            currentImageData: currentImageData,
            mode: currentMode
        ) {
            // Check if we got a non-empty response
            if !llmResponse.isEmpty {
                let bubbles = llmResponse.components(separatedBy: "\n\n")
                    .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

                // Only proceed if we have actual content
                if !bubbles.isEmpty {
                    // Show typing indicator.
                    await MainActor.run { isTyping = true }

                    // Deliver each bubble with a delay.
                    for (index, bubble) in bubbles.enumerated() {
                        await deliverMessageWithDelay(
                            bubble, isLastMessage: index == bubbles.count - 1)
                    }
                }
            }

            // Always clean up regardless of content
            await MainActor.run {
                isTyping = false
                isThinking = false
            }
        } else {
            // In case of an error, show a fallback response.
            await MainActor.run {
                let fallbackMessage = ChatMessage(
                    content:
                        "I seem to be having trouble connecting. Can we pause and reflect for a moment?",
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

    // Updated createCleanMessageHistory to handle full conversation history
    private func createCleanMessageHistory(from messages: [ChatMessage]) -> [ChatMessage] {
        // First ensure messages are in chronological order
        let sortedMessages = messages.sorted(by: { $0.timestamp < $1.timestamp })

        // Keep track of seen messages to avoid duplicates
        var seenMessages = Set<String>()
        var cleanHistory: [ChatMessage] = []

        for message in sortedMessages {
            // Create a unique identifier for this message
            let identifier = "\(message.isUser ? "user" : "assistant"):\(message.content)"

            // Only add if we haven't seen this exact message before
            if !seenMessages.contains(identifier) {
                seenMessages.insert(identifier)
                cleanHistory.append(message)
            }
        }

        // Check if we have a reasonable message count
        print(
            "Clean history contains \(cleanHistory.count) messages out of \(messages.count) original messages"
        )

        // If history is very long, we might want to trim it to avoid token limits
        // Typically, LLM APIs have a token limit (e.g., 4096 tokens for some models)
        // A reasonable estimate is ~100 tokens per message on average
        let maxMessages = 25  // This allows for ~2500 tokens of history

        if cleanHistory.count > maxMessages {
            print("Trimming history from \(cleanHistory.count) to \(maxMessages) messages")
            // Keep first message (often a greeting) and most recent messages
            var trimmedHistory: [ChatMessage] = []

            // Always include the first message if it's an assistant greeting
            if !cleanHistory.isEmpty && !cleanHistory[0].isUser {
                trimmedHistory.append(cleanHistory[0])
            }

            // Add the most recent messages up to the limit
            let recentMessages = Array(cleanHistory.suffix(maxMessages - trimmedHistory.count))
            trimmedHistory.append(contentsOf: recentMessages)

            return trimmedHistory
        }

        return cleanHistory
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
        if isViewingPreviousConversation {
            // Don't save if we're just viewing a previous conversation
            print("Not saving: just viewing previous conversation")
            return
        }

        // Check if we have new messages to save
        guard !newSessionMessages.isEmpty && newSessionMessages.contains(where: { $0.isUser })
        else {
            print("No new user messages to save.")
            return
        }

        // Create a chat session with ONLY the messages from this session and include the current mode
        let chatSession = ChatSession(
            id: conversationId,
            messages: newSessionMessages,
            timestamp: Date(),
            chatMode: currentMode
        )

        firebaseManager.saveChatSession(chatSession: chatSession) { result in
            switch result {
            case .success():
                print(
                    "Chat session saved successfully with \(self.newSessionMessages.count) messages for mode: \(self.currentMode)."
                )
            case .failure(let error):
                print("Error saving chat session: \(error.localizedDescription)")
            }
        }
    }

    func loadLastConversation() {
        if let lastSession = previousConversations.last {
            print(
                "Loading conversation with ID: \(lastSession.id), containing \(lastSession.messages.count) messages"
            )
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
            // Check for duplicates first
            checkForDuplicates(in: session.messages)

            conversationId = session.id
            messages = session.messages
            // Clear new session messages as we're loading an existing conversation
            newSessionMessages = []
            isViewingPreviousConversation = true
        }
    }

    // Add a method to continue the conversation with new messages
    func continueConversation() {
        // If we were viewing a previous conversation, switch to active mode
        if isViewingPreviousConversation {
            print("Continuing from previous conversation")
            isViewingPreviousConversation = false
            // Clear newSessionMessages to start tracking from here
            newSessionMessages = []
        }
    }

    private func filterMessagesByCurrentMode() {
        // Update the displayed messages based on the current mode
        switch currentMode {
        case .yin:
            // If yin messages are empty but we're switching to yin mode, initialize with greeting
            if yinMessages.isEmpty {
                let initialMessage = ChatMessage(
                    content: getInitialMessage(for: .yin),
                    isUser: false,
                    timestamp: Date(),
                    image: nil
                )
                yinMessages = [initialMessage]
            }
            messages = yinMessages
        case .yang:
            // If yang messages are empty but we're switching to yang mode, initialize with greeting
            if yangMessages.isEmpty {
                let initialMessage = ChatMessage(
                    content: getInitialMessage(for: .yang),
                    isUser: false,
                    timestamp: Date(),
                    image: nil
                )
                yangMessages = [initialMessage]
            }
            messages = yangMessages
        }
    }
}
