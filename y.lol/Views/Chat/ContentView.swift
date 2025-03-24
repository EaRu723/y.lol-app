//
//  Untitled.swift
//  y.lol
//
//  Created by Andrea Russo on 3/1/25.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.themeColors) private var colors
    
    @StateObject private var viewModel = ChatViewModel()
    @State private var showProfile = false
    @StateObject private var authManager = AuthenticationManager.shared
    
    @State private var isThinking: Bool = false
    @State private var messageText: String = ""
    
    // For scrolling to the latest message
    @State private var scrollProxy: ScrollViewProxy? = nil
    
    // For message editing
    @State private var editingMessageIndex: Int?
    @State private var isEditing: Bool = false
    @FocusState private var isFocused: Bool
    
    // Replace drawer with search
    @State private var isSearching = false
    
    private let hapticService = HapticService()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                (colorScheme == .dark ? Color.black : Color.white)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HeaderView(
                        isThinking: $isThinking,
                        showProfile: $showProfile,
                        isSearching: $isSearching,
                        currentMode: viewModel.currentMode,
                        onPillTapped: { mode in
                            viewModel.currentMode = mode
                            print("Switched to mode: \(mode)")
                        },
                        onSaveChat: {
                            viewModel.saveCurrentChatSession()
                        }
                    )
                    
                    // Optional: Add search UI when isSearching is true
                    if isSearching {
                        searchView()
                    }
                    
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.messages) { message in
                                    MessageView(message: message, index: 0, totalCount: viewModel.messages.count)
                                        .id(message.id)
                                        .transition(.asymmetric(
                                            insertion: .modifier(
                                                active: CustomTransitionModifier(offset: 20, opacity: 0, scale: 0.8),
                                                identity: CustomTransitionModifier(offset: 0, opacity: 1, scale: 1.0)
                                            ),
                                            removal: .opacity.combined(with: .scale(scale: 0.9))
                                        ))
                                }
                                
                                // Add typing indicator
                                if viewModel.isTyping {
                                    HStack {
                                        TypingIndicatorView()
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                                }
                                
                                if !isEditing {
                                    InlineEditorView(
                                        text: $messageText,
                                        isEditing: $isEditing,
                                        isFocused: _isFocused,
                                        onSend: sendMessage,
                                        hapticService: hapticService
                                    )
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                                }
                            }
                            .padding(.vertical)
                        }
                        .onAppear {
                            scrollProxy = proxy
                            
                            // When the view appears, scroll to the initial message
                            if !viewModel.messages.isEmpty {
                                scrollToLatest()
                            }
                        }
                        .onChange(of: viewModel.messages.count) { oldCount, newCount in
                            if newCount > oldCount {
                                scrollToLatest()
                            }
                        }
                    }
                }
                
                .onChange(of: isThinking) { oldValue, newValue in
                    if newValue {
                        startBreathingHaptics()
                    } else {
                        stopBreathingHaptics()
                    }
                }
                
                .sheet(isPresented: $showProfile) {
                    ProfileView()
                        .environmentObject(authManager)
                }
            }
        }
    }
    
    // New search view
    @ViewBuilder
    private func searchView() -> some View {
        SearchView(isSearching: $isSearching) { searchText in
            // Handle search
        }
    }
    
    private func startBreathingHaptics() {
        hapticService.startBreathing()
    }
    
    private func stopBreathingHaptics() {
        hapticService.stopBreathing()
        isThinking = false
    }
    
    private func sendMessage() {
        // Set the message in the ViewModel before sending
        viewModel.messageText = messageText
        
        // Clear local message text
        messageText = ""
        
        // Delegate to the ViewModel's sendMessage
        Task {
            await viewModel.sendMessage()
        }
    }
    
    private func scrollToLatest() {
        guard let lastMessage = viewModel.messages.last else { return }
        
        // Add a small delay to allow rendering to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                scrollProxy?.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

struct CustomTransitionModifier: ViewModifier {
    let offset: CGFloat
    let opacity: Double
    let scale: CGFloat
    
    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .opacity(opacity)
            .scaleEffect(scale)
            .blur(radius: opacity == 0 ? 5 : 0)
    }
}
