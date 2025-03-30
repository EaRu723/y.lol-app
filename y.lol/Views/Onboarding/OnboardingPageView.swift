import SwiftUI

struct OnboardingPageView: View {
    let messages: [OnboardingMessage]
    let buttonText: String
    let hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle
    let isLastPage: Bool
    let showSignInButton: Bool
    let showHandleInput: Bool
    let onContinue: (() -> Void)?
    let onSignIn: (() -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.themeColors) private var colors
    
    @State private var displayedMessages: [OnboardingMessage] = []
    @State private var isTyping: Bool = false
    @State private var typingSender: Sender? = nil
    @State private var currentMessageIndex: Int = 0
    @State private var animationTask: Task<Void, Never>? = nil
    
    @State private var handle: String = ""
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            SimplifiedYinYangView(
                size: 100,
                lightColor: colorScheme == .light ? .white : YTheme.Colors.parchmentDark,
                darkColor: colorScheme == .light ? YTheme.Colors.textLight : YTheme.Colors.textDark
            )
            .rotationEffect(.degrees(90))
            
            Spacer()
            
            chatMessagesView
                .frame(minHeight: 150)

            if showHandleInput {
                handleInputView
                    .padding(.bottom, 10)
            }
            
            Spacer()
            
            actionButtonView
            
            Spacer().frame(height: 40)
        }
        .onAppear {
            startTypingAnimation()
        }
        .onChange(of: messages.map { $0.id }) { _ in
            startTypingAnimation()
        }
        .onDisappear {
            animationTask?.cancel()
        }
    }
    
    @ViewBuilder
    private var chatMessagesView: some View {
        ScrollView {
             VStack(alignment: .leading, spacing: 12) {
                 ForEach(displayedMessages) { message in
                     SingleChatBubbleView(message: message)
                         .transition(.asymmetric(
                             insertion: .scale(scale: 0.8, anchor: message.sender == .yin ? .bottomLeading : .bottomTrailing)
                                         .combined(with: .opacity)
                                         .animation(.spring(response: 0.4, dampingFraction: 0.7)),
                             removal: .opacity.animation(.easeInOut(duration: 0.2))
                         ))
                 }

                 if isTyping, let sender = typingSender {
                     TypingBubbleView(sender: sender)
                         .transition(.opacity.animation(.easeInOut(duration: 0.3)))
                 }
                 
                 if !displayedMessages.isEmpty || isTyping {
                     Spacer()
                 }
             }
             .padding(.horizontal, 8)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private var handleInputView: some View {
        VStack(spacing: 10) {
            Text("Choose your handle")
                .font(YTheme.Typography.serif(size: 16, weight: .medium))
                .foregroundColor(colors.text)
            
            HStack {
                Text("@y.")
                    .font(YTheme.Typography.serif(size: 18, weight: .medium))
                    .foregroundColor(colors.text.opacity(0.7))
                
                TextField("yourname", text: $handle)
                    .font(YTheme.Typography.serif(size: 18, weight: .medium))
                    .foregroundColor(colors.text)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 10)
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(colors.background)
            )
            .padding(.horizontal, 40)
        }
    }
    
    @ViewBuilder
    private var actionButtonView: some View {
         if showSignInButton {
             Button(action: {
                 let generator = UIImpactFeedbackGenerator(style: hapticStyle)
                 generator.impactOccurred()
                 onSignIn?()
             }) {
                 SignInWithAppleButtonView(
                     type: .signIn,
                     style: colorScheme == .dark ? .white : .black,
                     cornerRadius: 10
                 )
                 .frame(height: 50)
             }
             .frame(width: 250)
             .padding(.horizontal, YTheme.Spacing.large)
         } else {
             Button(action: {
                 let generator = UIImpactFeedbackGenerator(style: hapticStyle)
                 generator.impactOccurred()
                 onContinue?()
             }) {
                 HStack {
                     Image(systemName: "arrow.right")
                         .font(.system(size: 20))
                     
                     Text(buttonText)
                         .font(YTheme.Typography.body)
                 }
                 .foregroundColor(colors.text)
                 .padding(.horizontal, 30)
                 .padding(.vertical, 12)
                 .background(
                     RoundedRectangle(cornerRadius: 10)
                         .fill(colors.accent.opacity(0.01))
                 )
                 .overlay(
                     RoundedRectangle(cornerRadius: 10)
                         .stroke(colors.text, lineWidth: 1)
                 )
             }
             .fixedSize(horizontal: true, vertical: false)
             .frame(maxWidth: 250)
             .padding(.horizontal, YTheme.Spacing.large)
             .disabled(showHandleInput && handle.isEmpty)
             .opacity(showHandleInput && handle.isEmpty ? 0.5 : 1.0)
         }
    }
    
    private func startTypingAnimation() {
        animationTask?.cancel()
        
        displayedMessages = []
        isTyping = false
        typingSender = nil
        currentMessageIndex = 0
        
        animationTask = Task {
            await showNextMessageWithTyping()
        }
    }
    
    private func showNextMessageWithTyping() async {
        guard !Task.isCancelled else { return }
        
        guard currentMessageIndex < messages.count else {
            isTyping = false
            typingSender = nil
            let generator = UIImpactFeedbackGenerator(style: hapticStyle)
            generator.impactOccurred()
            return
        }

        let message = messages[currentMessageIndex]
        let typingDuration = 0.8
        let delayBeforeNext = 0.6

        typingSender = message.sender
        withAnimation(.easeInOut) {
             isTyping = true
        }
        
        do {
             try await Task.sleep(nanoseconds: UInt64(typingDuration * 1_000_000_000))
             guard !Task.isCancelled else { return }

             typingSender = nil
             withAnimation(.easeInOut) {
                 isTyping = false
             }
             try await Task.sleep(nanoseconds: 100_000_000)
             guard !Task.isCancelled else { return }

             withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                 displayedMessages.append(message)
             }
             
             currentMessageIndex += 1
             
             try await Task.sleep(nanoseconds: UInt64(delayBeforeNext * 1_000_000_000))
             guard !Task.isCancelled else { return }
             
             await showNextMessageWithTyping()
             
        } catch {
             print("Animation task cancelled.")
             isTyping = false
             typingSender = nil
        }
    }
}

#Preview {
    OnboardingPageView(
        messages: [
            OnboardingMessage(sender: .yin, text: "First message from Yin."),
            OnboardingMessage(sender: .yang, text: "Then Yang responds."),
            OnboardingMessage(sender: .yang, text: "Yang adds another thought."),
            OnboardingMessage(sender: .yin, text: "Yin gets the last word here.")
        ],
        buttonText: "Continue",
        hapticStyle: .light,
        isLastPage: false,
        showSignInButton: false,
        showHandleInput: false,
        onContinue: {},
        onSignIn: nil
    )
    .padding()
    .background(Color(.systemGray5))
} 
