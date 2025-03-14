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
    
    @State private var messageText: String = ""
    @FocusState private var isFocused: Bool
    
    // For message editing
    @State private var isEditing: Bool = false
    private let hapticService = HapticService()
    
    var body: some View {
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
                        HStack {
                            TextField("Message", text: $messageText, axis: .vertical)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(20)
                                .focused($isFocused)
                                .frame(minHeight: 40)
                                .animation(.easeInOut(duration: 0.2), value: messageText)
                            
                            Button(action: sendMessage) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(!messageText.isEmpty ? colors.text(opacity: 1) : colors.text(opacity: 0.3))
                            }
                            .disabled(messageText.isEmpty)
                        }
                        .padding()
                        .background(colors.background)
                        
                        KeyboardToolbarView(text: $messageText, onSend: sendMessage, hapticService: hapticService)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
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
