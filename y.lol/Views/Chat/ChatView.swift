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
    
    @StateObject var viewModel = ChatViewModel()
    @State private var showProfile = false
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var isAuthenticated = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    @State private var messageText: String = ""
    @FocusState private var isFocused: Bool
    
    // For message editing
    @State private var isEditing: Bool = false
    private let hapticService = HapticService()
    
    // Add this state variable at the top with other @State properties
    @State private var isActionsExpanded: Bool = false
    
    // Add an auth state listener
    @State private var authStateListener: AuthStateDidChangeListenerHandle?
    
    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView()
                    .environmentObject(authManager)
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
                            
                            // Action Pills and Input area
                            VStack {
                                if !isActionsExpanded {
                                    ActionPillsView(currentMode: viewModel.currentMode) { mode in
                                        handlePillTap(mode)
                                    }
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                                }
                                
                                MessageInputView(
                                    messageText: $messageText,
                                    isActionsExpanded: $isActionsExpanded,
                                    onSend: sendMessage
                                )
                                .padding()
                            }
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActionsExpanded)
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
            setupAuthListener()
            checkAuthStatus()
            print("Debug - ChatView appeared, auth status: \(isAuthenticated)")
        }
        .onDisappear {
            // Remove listener when view disappears
            if let listener = authStateListener {
                Auth.auth().removeStateDidChangeListener(listener)
            }
        }
    }
    
    private func setupAuthListener() {
        // Remove existing listener if any
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
        
        // Set up a new listener
        authStateListener = Auth.auth().addStateDidChangeListener { auth, user in
            print("Debug - Auth state changed, user: \(user?.uid ?? "nil")")
            isAuthenticated = user != nil
        }
    }
    
    private func checkAuthStatus() {
        let wasAuthenticated = isAuthenticated
        isAuthenticated = Auth.auth().currentUser != nil
        
        print("Debug - Manual auth check: \(isAuthenticated)")
        
        if !wasAuthenticated && isAuthenticated {
            print("Debug - User just became authenticated")
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        

        viewModel.messageText = messageText

        DispatchQueue.main.async {
            self.messageText = ""
        }
        
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
    
    // Add this function to handle pill taps
    private func handlePillTap(_ mode: FirebaseManager.ChatMode) {
        viewModel.currentMode = mode
        print("Switched to mode: \(mode)")
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}
