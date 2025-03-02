//
//  Untitled.swift
//  y.lol
//
//  Created by Andrea Russo on 3/1/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    // State for messages
    @State private var messages: [ChatMessage] = []
    
    // Constants for styling
    private var colors: (
        background: Color,
        text: Color,
        accent: Color
    ) {
        switch colorScheme {
        case .light:
            return (
                background: Color(hex: "F5F2E9"),    // light parchment
                text: Color(hex: "2C2C2C"),          // dark gray
                accent: Color(hex: "E4D5B7")         // warm beige
            )
        case .dark:
            return (
                background: Color(hex: "1C1C1E"),    // dark background
                text: Color(hex: "F5F2E9"),          // light text
                accent: Color(hex: "B8A179")         // darker warm accent
            )
        @unknown default:
            return (
                background: Color(hex: "F5F2E9"),
                text: Color(hex: "2C2C2C"),
                accent: Color(hex: "E4D5B7")
            )
        }
    }
    
    // Update backgroundColor to use the palette
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
    
    // Add these state variables
    @State private var editingMessageIndex: Int?
    @State private var isEditing: Bool = false
    @FocusState private var isFocused: Bool
    
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
    
    // Add this property to ContentView
    private let hapticService = HapticService()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with texture
                colors.background
                    .overlay(
                        Color.primary
                            .opacity(0.03)
                            .blendMode(.multiply)
                    )
                    .overlay(
                        ParticleSystem(isThinking: $isThinking, geometry: geometry)
                            .allowsHitTesting(false)
                    )
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HeaderView(isThinking: $isThinking)
                    
                    // Modify the TabView section
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
                                        
                                        // Only show the editor on the last page and when not editing
                                        if !isEditing && pageIndex == paginatedMessages.count - 1 {
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
                }
                
                // Haptic breathing effect
                .onChange(of: isThinking) { oldValue, newValue in
                    if newValue {
                        startBreathingHaptics()
                    } else {
                        stopBreathingHaptics()
                    }
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
    
    // Replace existing haptic methods with these:
    private func startBreathingHaptics() {
        hapticService.startBreathing()
    }
    
    private func stopBreathingHaptics() {
        hapticService.stopBreathing()
        isThinking = false
    }
    
    // Update sendMessage to handle the inline editor
    private func sendMessage() {
        // Trim whitespace and check if message is empty
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        isEditing = false
        isFocused = false
        
        // Play send haptic feedback
        hapticService.playSendFeedback()
        
        let newMessage = ChatMessage(
            content: trimmedMessage,
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
            
            // Play receive haptic feedback
            hapticService.playReceiveFeedback()
            
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
    @Environment(\.colorScheme) private var colorScheme
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
                .foregroundColor(colorScheme == .light ? 
                    Color(hex: "2C2C2C").opacity(message.isUser ? 0.9 : 0.75) :
                    Color(hex: "F5F2E9").opacity(message.isUser ? 0.9 : 0.75))
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

// Add these new structures after CustomTransitionModifier and before ContentView
struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var scale: CGFloat
    var opacity: Double
    var speed: CGFloat
}

struct ParticleSystem: View {
    @Binding var isThinking: Bool
    let geometry: GeometryProxy
    @State private var particles: [Particle] = []
    @State private var timer: Timer?
    
    var body: some View {
        Canvas { context, size in
            for particle in particles {
                context.opacity = particle.opacity
                context.scaleBy(x: particle.scale, y: particle.scale)
                
                let rect = CGRect(x: particle.position.x, y: particle.position.y, width: 4, height: 4)
                context.fill(Path(ellipseIn: rect), with: .color(.black.opacity(0.1)))
            }
        }
        .onAppear {
            createInitialParticles()
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1/30, repeats: true) { _ in
            updateParticles()
        }
    }
    
    private func createInitialParticles() {
        for _ in 0..<20 {
            particles.append(
                Particle(
                    position: CGPoint(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: CGFloat.random(in: 0...geometry.size.height)
                    ),
                    scale: CGFloat.random(in: 0.5...1.5),
                    opacity: Double.random(in: 0.1...0.3),
                    speed: CGFloat.random(in: 0.2...0.8)
                )
            )
        }
    }
    
    private func updateParticles() {
        for index in particles.indices {
            var particle = particles[index]
            let baseSpeed = particle.speed
            let currentSpeed = isThinking ? baseSpeed * 2 : baseSpeed
            
            particle.position.y -= currentSpeed
            
            if particle.position.y < -10 {
                particle.position.y = geometry.size.height + 10
                particle.position.x = CGFloat.random(in: 0...geometry.size.width)
            }
            
            particles[index] = particle
        }
    }
}

// Add this struct before ContentView
struct HeaderView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var showButtons = false
    @Binding var isThinking: Bool
    
    var body: some View {
        HStack {
            Button(action: {
                // Menu action
            }) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20))
                    .foregroundColor(colorScheme == .light ? 
                        Color(hex: "2C2C2C").opacity(0.8) :
                        Color(hex: "F5F2E9").opacity(0.8))
            }
            .opacity(showButtons ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: showButtons)
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    showButtons.toggle()
                }
            }) {
                YLogoView(size: 40, isLoading: isThinking)
            }
            
            Spacer()
            
            Button(action: {
                // Profile action
            }) {
                Image(systemName: "person.circle")
                    .font(.system(size: 20))
                    .foregroundColor(colorScheme == .light ? 
                        Color(hex: "2C2C2C").opacity(0.8) :
                        Color(hex: "F5F2E9").opacity(0.8))
            }
            .opacity(showButtons ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: showButtons)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
}

// Add this new view for the inline editor
struct InlineEditorView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var text: String
    @Binding var isEditing: Bool
    @FocusState var isFocused: Bool
    var onSend: () -> Void
    let hapticService: HapticService
    
    var body: some View {
        TextEditor(text: $text)
            .focused($isFocused)
            .frame(minHeight: 36, maxHeight: 120)
            .font(.system(size: 16, weight: .regular, design: .serif))
            .foregroundColor(colorScheme == .light ? 
                Color(hex: "2C2C2C").opacity(0.9) :
                Color(hex: "F5F2E9").opacity(0.9))
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .padding(.vertical, 8)
            .padding(.horizontal, 20)
            .onChange(of: text) { oldValue, newValue in
                if newValue.count > oldValue.count {
                    hapticService.playTypingFeedback()
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    KeyboardToolbarView(text: $text, onSend: onSend, hapticService: hapticService)
                }
            }
            .onAppear {
                isFocused = true
            }
            .onTapGesture {
                isEditing = true
            }
    }
    
    private var colors: (background: Color, text: Color, accent: Color) {
        switch colorScheme {
        case .light:
            return (
                background: Color(hex: "F5F2E9"),
                text: Color(hex: "2C2C2C"),
                accent: Color(hex: "E4D5B7")
            )
        case .dark:
            return (
                background: Color(hex: "1C1C1E"),
                text: Color(hex: "F5F2E9"),
                accent: Color(hex: "B8A179")
            )
        @unknown default:
            return (
                background: Color(hex: "F5F2E9"),
                text: Color(hex: "2C2C2C"),
                accent: Color(hex: "E4D5B7")
            )
        }
    }
}

