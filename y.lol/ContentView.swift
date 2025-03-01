//
//  Untitled.swift
//  y.lol
//
//  Created by Andrea Russo on 3/1/25.
//

import SwiftUI

struct ContentView: View {
    // State for messages
    @State private var messages: [ChatMessage] = []
    
    // Constants for styling
    private let backgroundColor = Color(hex: "F5F2E9")
    private let textColor = Color(hex: "2C2C2C").opacity(0.85)
    
    // Add after backgroundColor declaration
    @State private var isThinking: Bool = false
    
    // Add after existing state variables
    @State private var messageText: String = ""
    
    // Add this state variable at the top of ContentView
    @State private var scrollProxy: ScrollViewProxy? = nil
    
    // Add these state variables to ContentView
    @State private var currentPage = 0
    private let messagesPerPage = 5
    
    // Add this computed property to ContentView
    private var paginatedMessages: [[ChatMessage]] {
        var pages: [[ChatMessage]] = []
        var currentPage: [ChatMessage] = []
        
        for message in messages {
            if currentPage.isEmpty {
                currentPage.append(message)
            } else if (message.isUser && currentPage.last?.isUser == false) ||
                      (!message.isUser && currentPage.last?.isUser == true) {
                currentPage.append(message)
                pages.append(currentPage)
                currentPage = []
            } else {
                pages.append([message])
            }
        }
        
        if !currentPage.isEmpty {
            pages.append(currentPage)
        }
        
        return pages
    }
    
    // Add this state variable to ContentView
    @State private var hasInitialized = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with texture
                backgroundColor
                    .overlay(
                        Color.black
                            .opacity(0.03)
                            .blendMode(.multiply)
                    )
                    .ignoresSafeArea()
                
                // Haptic breathing effect
                .onChange(of: isThinking) { oldValue, newValue in
                    if newValue {
                        startBreathingHaptics()
                    } else {
                        stopBreathingHaptics()
                    }
                }
                
                // Spiral message layout
                TabView(selection: $currentPage) {
                    ForEach(Array(paginatedMessages.enumerated()), id: \.offset) { pageIndex, pageMessages in
                        ScrollViewReader { proxy in
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(pageMessages) { message in
                                        MessageView(message: message, index: 0, totalCount: messages.count)
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
                            .onAppear {
                                scrollProxy = proxy
                            }
                        }
                        .tag(pageIndex)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onChange(of: messages.count) { oldCount, newCount in
                    if newCount > oldCount && newCount % messagesPerPage == 1 {
                        turnToNextPage()
                    }
                }
                
                // Message input view
                VStack {
                    Spacer()
                    HStack(spacing: 16) {
                        TextField("Write your message...", text: $messageText)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(hex: "E4D5B7").opacity(0.7))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color(hex: "2C2C2C").opacity(0.2), lineWidth: 0.5)
                                    )
                            )
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 16, weight: .regular, design: .serif))
                            .foregroundColor(textColor)
                        
                        Button(action: sendMessage) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(Color(hex: "2C2C2C").opacity(0.8))
                                .background(
                                    Circle()
                                        .fill(Color(hex: "E4D5B7"))
                                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
                
                // Add this to the body of ContentView, right after ZStack {
                .onAppear {
                    if !hasInitialized {
                        let initialMessage = ChatMessage(
                            content: "how r u",
                            isUser: false,
                            timestamp: Date()
                        )
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            messages.append(initialMessage)
                        }
                        hasInitialized = true
                    }
                }
            }
        }
    }
    
    // Add these methods to ContentView
    private func startBreathingHaptics() {
        // Create a repeating timer for the breathing effect
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            guard isThinking else {
                timer.invalidate()
                return
            }
            
            let generator = UIImpactFeedbackGenerator(style: .soft)
            
            // Fade in
            for intensity in stride(from: 0.0, to: 1.0, by: 0.2) {
                DispatchQueue.main.asyncAfter(deadline: .now() + intensity) {
                    generator.impactOccurred(intensity: intensity)
                }
            }
            
            // Fade out
            for intensity in stride(from: 1.0, to: 0.0, by: -0.2) {
                DispatchQueue.main.asyncAfter(deadline: .now() + (2.0 - intensity)) {
                    generator.impactOccurred(intensity: intensity)
                }
            }
        }
    }
    
    private func stopBreathingHaptics() {
        isThinking = false
    }
    
    // Add this method to ContentView
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let newMessage = ChatMessage(
            content: messageText,
            isUser: true,
            timestamp: Date()
        )
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            messages.append(newMessage)
            currentPage = paginatedMessages.count - 1
        }
        
        messageText = ""
        isThinking = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isThinking = false
            let response = ChatMessage(
                content: "This is a simulated response",
                isUser: false,
                timestamp: Date()
            )
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                messages.append(response)
                currentPage = paginatedMessages.count - 1
            }
        }
    }
    
    // Add this helper function to ContentView
    private func turnToNextPage() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            currentPage += 1
        }
    }
    
    // Add this helper function to ContentView
    private func scrollToLatest() {
        guard let lastMessage = messages.last else { return }
        if messages.count % messagesPerPage == 1 {
            // Let the page turn animation complete before scrolling
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    scrollProxy?.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
        } else {
            withAnimation {
                scrollProxy?.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

// Message model
struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
}

// Individual message view
struct MessageView: View {
    let message: ChatMessage
    let index: Int
    let totalCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !message.isUser {
                Text("Y")
                    .font(.system(size: 10, weight: .medium, design: .serif))
                    .foregroundColor(Color(hex: "2C2C2C").opacity(0.4))
                    .padding(.bottom, 4)
            }
            
            Text(message.content)
                .font(.system(size: message.isUser ? 16 : 14, weight: message.isUser ? .regular : .light, design: .serif))
                .foregroundColor(Color(hex: "2C2C2C").opacity(message.isUser ? 0.9 : 0.75))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            
            Text(formatTimestamp(message.timestamp))
                .font(.system(size: 8, weight: .light))
                .foregroundColor(Color(hex: "2C2C2C").opacity(0.3))
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Color hex extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Add this extension for array chunking
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// Add this struct after the Color extension and before ContentView
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

