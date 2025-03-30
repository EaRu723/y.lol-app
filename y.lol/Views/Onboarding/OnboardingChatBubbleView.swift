import SwiftUI

struct OnboardingChatBubbleView: View {
    let yinText: String
    let yangText: String
    let isYinTyping: Bool
    let isYangTyping: Bool
    let showYinMessage: Bool
    let showYangMessage: Bool
    
    init(
        yinText: String,
        yangText: String,
        isYinTyping: Bool = false,
        isYangTyping: Bool = false,
        showYinMessage: Bool = true,
        showYangMessage: Bool = true
    ) {
        self.yinText = yinText
        self.yangText = yangText
        self.isYinTyping = isYinTyping
        self.isYangTyping = isYangTyping
        self.showYinMessage = showYinMessage
        self.showYangMessage = showYangMessage
    }
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.themeColors) private var colors
    
    var body: some View {
        VStack(spacing: 16) {
            // Yin message with angel emoji
            HStack {
                if isYinTyping {
                    typingBubble(emoji: "😇", isYinMessage: true)
                        .transition(.opacity)
                } else if showYinMessage && !yinText.isEmpty {
                    messageBubble(
                        emoji: "😇",
                        text: yinText,
                        isYinMessage: true
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity).animation(.spring(response: 0.3, dampingFraction: 0.7)),
                        removal: .opacity
                    ))
                }
                
                Spacer(minLength: 40)
            }
            
            // Yang message with devil emoji
            HStack {
                if isYangTyping {
                    typingBubble(emoji: "😈", isYinMessage: false)
                        .transition(.opacity)
                } else if showYangMessage && !yangText.isEmpty {
                    messageBubble(
                        emoji: "😈",
                        text: yangText,
                        isYinMessage: false
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity).animation(.spring(response: 0.3, dampingFraction: 0.7)),
                        removal: .opacity
                    ))
                }
                
                Spacer(minLength: 40)
            }
        }
        .padding(.horizontal, 8)
        .animation(.easeInOut, value: isYinTyping)
        .animation(.easeInOut, value: isYangTyping)
        .animation(.easeInOut, value: showYinMessage)
        .animation(.easeInOut, value: showYangMessage)
    }
    
    private func messageBubble(emoji: String, text: String, isYinMessage: Bool) -> some View {
        HStack(alignment: .top, spacing: 4) {
            Text(emoji)
                .font(.system(size: 24))
                .padding(.top, 6)
                
            Text(text)
                .font(YTheme.Typography.serif(size: 16, weight: .light))
                .foregroundColor(colors.aiMessageText)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(colors.aiMessageBubble)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isYinMessage ? Color.blue.opacity(0.1) : Color.red.opacity(0.1), lineWidth: 1)
                )
                .frame(maxWidth: UIScreen.main.bounds.width * 0.67, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private func typingBubble(emoji: String, isYinMessage: Bool) -> some View {
        HStack(alignment: .top, spacing: 4) {
            Text(emoji)
                .font(.system(size: 24))
                .padding(.top, 6)
                
                TypingIndicatorDots()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(colors.aiMessageBubble)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isYinMessage ? Color.blue.opacity(0.1) : Color.red.opacity(0.1), lineWidth: 1)
                    )
        }
    }
}

// Typing indicator dots component
struct TypingIndicatorDots: View {
    @State private var firstDotOpacity: Double = 0.4
    @State private var secondDotOpacity: Double = 0.4
    @State private var thirdDotOpacity: Double = 0.4
    
    var body: some View {
        HStack(spacing: 4) {
            DotView(opacity: $firstDotOpacity)
            DotView(opacity: $secondDotOpacity)
            DotView(opacity: $thirdDotOpacity)
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        let animation = Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)
        
        withAnimation(animation) {
            firstDotOpacity = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(animation) {
                secondDotOpacity = 1.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(animation) {
                thirdDotOpacity = 1.0
            }
        }
    }
}

struct DotView: View {
    @Binding var opacity: Double
    
    var body: some View {
        Circle()
            .frame(width: 7, height: 7)
            .opacity(opacity)
    }
}

// Preview
#Preview {
    VStack(spacing: 30) {
        OnboardingChatBubbleView(
            yinText: "welcome to a space of balance",
            yangText: "where opposites can coexist"
        )
        
        Divider()
        
        OnboardingChatBubbleView(
            yinText: "you could be anywhere right now",
            yangText: "but you chose to be here",
            isYinTyping: true,
            showYinMessage: false
        )
        
        Divider()
        
        OnboardingChatBubbleView(
            yinText: "welcome to a space of balance",
            yangText: "",
            isYangTyping: true,
            showYangMessage: false
        )
        
        Divider()
        
        OnboardingChatBubbleView(
            yinText: "",
            yangText: "",
            showYinMessage: false,
            showYangMessage: false
        )
    }
    .padding()
    .background(Color(.systemBackground))
} 