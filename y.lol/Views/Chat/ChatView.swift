//
//  ChatView.swift
//  y.lol
//
//  Created by Andrea Russo on 3/13/25.
//

import Foundation
import SwiftUI
import FirebaseAuth

struct ChatView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.themeColors) private var colors
    
    @StateObject private var viewModel = ChatViewModel()
    @State private var showProfile = false
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var isAuthenticated = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    @State private var messageText: String = ""
    @FocusState private var isFocused: Bool
    
    // For message editing
    @State private var isEditing: Bool = false
    private let hapticService = HapticService()
    
    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView()
            } else if !isAuthenticated {
                LoginView()
                    .environmentObject(authManager)
            } else {
                GeometryReader { geometry in
                    ZStack {
                        // Background with texture
                        colors.backgroundWithNoise
                            .ignoresSafeArea()
                        
                        VStack(spacing: 0) {
                            HeaderView(isThinking: $viewModel.isThinking, showProfile: $showProfile)
                            
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
                                    }
                                    .padding(.vertical)
                                }
                                .onChange(of: viewModel.messages.count) { oldCount, newCount in
                                    if newCount > oldCount {
                                        scrollToLatest(proxy: proxy)
                                    }
                                }
                            }
                            
                            // Input area
                            VStack {
                                MessageInputView(
                                    messageText: $messageText,
                                    onSend: sendMessage
                                )
                                .padding()
                                .background(colors.background)
                            }
                        }
                        .onChange(of: viewModel.isThinking) { oldValue, newValue in
                            if newValue {
                                hapticService.startBreathing()
                            } else {
                                hapticService.stopBreathing()
                            }
                        }
                        .sheet(isPresented: $showProfile) {
                            ProfileView()
                                .environmentObject(authManager)
                        }
                    }
                }
            }
        }
        .onAppear {
            checkAuthStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            checkAuthStatus()
        }
    }
    
    private func checkAuthStatus() {
        isAuthenticated = Auth.auth().currentUser != nil
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        // Set the message in the ViewModel before sending
        viewModel.messageText = messageText
        
        // Clear local message text
        messageText = ""
        
        // Delegate to the ViewModel's sendMessage
        Task {
            await viewModel.sendMessage()
        }
    }
    
    private func scrollToLatest(proxy: ScrollViewProxy) {
        guard let lastMessage = viewModel.messages.last else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}
