import SwiftUI

struct SingleChatBubbleView: View {
    let message: OnboardingMessage
    
    @Environment(\.themeColors) private var colors
    
    private var emoji: String {
        message.sender == .yin ? "😇" : "😈"
    }
    
    private var alignment: Alignment {
        message.sender == .yin ? .leading : .trailing
    }
    
    private var bubbleColor: Color {
        colors.aiMessageBubble // Or differentiate if needed
    }
    
    private var strokeColor: Color {
        message.sender == .yin ? Color.blue.opacity(0.1) : Color.red.opacity(0.1)
    }

    var body: some View {
        HStack(spacing: 0) {
            if message.sender == .yang { Spacer(minLength: 40) } // Push yang to the right
            
            HStack(alignment: .top, spacing: 4) {
                 // Order emoji based on sender for natural LTR reading
                 if message.sender == .yin {
                     EmojiView(emoji: emoji)
                 }

                Text(message.text)
                    .font(YTheme.Typography.serif(size: 16, weight: .light))
                    .foregroundColor(colors.aiMessageText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(bubbleColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(strokeColor, lineWidth: 1)
                    )
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.67, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)

                 if message.sender == .yang {
                     EmojiView(emoji: emoji)
                 }
            }
            
            if message.sender == .yin { Spacer(minLength: 40) } // Push yin to the left
        }
        .frame(maxWidth: .infinity, alignment: alignment)
    }
    
    // Helper for consistent emoji presentation
    private func EmojiView(emoji: String) -> some View {
        Text(emoji)
            .font(.system(size: 24))
            .padding(.top, 6) // Align with text bubble
    }
}

struct TypingBubbleView: View {
    let sender: Sender
    
    @Environment(\.themeColors) private var colors
    
    private var emoji: String {
        sender == .yin ? "😇" : "😈"
    }
    
    private var alignment: Alignment {
        sender == .yin ? .leading : .trailing
    }

    private var bubbleColor: Color {
        colors.aiMessageBubble
    }
    
    private var strokeColor: Color {
        sender == .yin ? Color.blue.opacity(0.1) : Color.red.opacity(0.1)
    }

    var body: some View {
         HStack(spacing: 0) {
             if sender == .yang { Spacer(minLength: 40) }
             
             HStack(alignment: .top, spacing: 4) {
                 if sender == .yin {
                     EmojiView(emoji: emoji)
                 }

                 TypingIndicatorDots() // Reuse from OnboardingChatBubbleView
                     .padding(.horizontal, 12)
                     .padding(.vertical, 11) // Adjust vertical padding for dots
                     .background(bubbleColor)
                     .clipShape(RoundedRectangle(cornerRadius: 16))
                     .overlay(
                         RoundedRectangle(cornerRadius: 16)
                             .stroke(strokeColor, lineWidth: 1)
                     )
                 
                 if sender == .yang {
                     EmojiView(emoji: emoji)
                 }
             }
             
             if sender == .yin { Spacer(minLength: 40) }
         }
         .frame(maxWidth: .infinity, alignment: alignment)
    }
    
    // Helper for consistent emoji presentation
    private func EmojiView(emoji: String) -> some View {
        Text(emoji)
            .font(.system(size: 24))
            .padding(.top, 6)
    }
}

// Assuming TypingIndicatorDots and DotView are accessible (e.g., defined globally or copied here)
// If not, copy TypingIndicatorDots and DotView structs from OnboardingChatBubbleView.swift here.

#Preview {
    VStack(alignment: .leading, spacing: 20) {
        SingleChatBubbleView(message: OnboardingMessage(sender: .yin, text: "Hello from Yin! This is a slightly longer message to test wrapping."))
        SingleChatBubbleView(message: OnboardingMessage(sender: .yang, text: "Yang here. Short and sweet."))
        TypingBubbleView(sender: .yin)
        TypingBubbleView(sender: .yang)
    }
    .padding()
    .background(Color.gray.opacity(0.2))
} 