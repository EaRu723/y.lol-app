import SwiftUI

struct OnboardingChatBubbleView: View {
    let yinText: String
    let yangText: String
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.themeColors) private var colors
    
    var body: some View {
        VStack(spacing: 16) {
            // Yin message with angel emoji
            if !yinText.isEmpty {
                HStack {
                    messageBubble(
                        emoji: "😇",
                        text: yinText,
                        isYinMessage: true
                    )
                    
                    Spacer(minLength: 40)
                }
            }
            
            // Yang message with devil emoji
            if !yangText.isEmpty {
                HStack {
                    messageBubble(
                        emoji: "😈",
                        text: yangText,
                        isYinMessage: false
                    )
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .padding(.horizontal, 8)
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
                .clipShape(BubbleShape(
                    isUser: false,
                    isFirstInGroup: true,
                    isLastInGroup: true
                ))
                .overlay(
                    BubbleShape(
                        isUser: false,
                        isFirstInGroup: true,
                        isLastInGroup: true
                    )
                    .stroke(isYinMessage ? Color.blue.opacity(0.1) : Color.red.opacity(0.1), lineWidth: 1)
                )
                .frame(maxWidth: UIScreen.main.bounds.width * 0.67, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
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
            yangText: "but you chose to be here"
        )
        
        Divider()
        
        // Animation states
        OnboardingChatBubbleView(
            yinText: "welcome to a space of balance",
            yangText: ""
        )
        
        OnboardingChatBubbleView(
            yinText: "",
            yangText: ""
        )
    }
    .padding()
    .background(Color(.systemBackground))
} 