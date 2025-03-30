import SwiftUI

struct SingleChatBubbleView: View {
    let message: OnboardingMessage
    
    @Environment(\.themeColors) private var colors
    
    private var emoji: String { message.sender == .yin ? "😇" : "😈" }
    private var alignment: Alignment { message.sender == .yin ? .leading : .trailing }
    private var bubbleColor: Color { colors.aiMessageBubble }
    private var strokeColor: Color { message.sender == .yin ? Color.blue.opacity(0.1) : Color.red.opacity(0.1) }

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            if message.sender == .yin {
                EmojiView(emoji: emoji)
            } else {
                Spacer()
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

            if message.sender == .yang {
                EmojiView(emoji: emoji)
            } else {
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func EmojiView(emoji: String) -> some View {
        Text(emoji)
            .font(.system(size: 24))
            .padding(.top, 6)
    }
}

struct TypingBubbleView: View {
    let sender: Sender
    
    @Environment(\.themeColors) private var colors
    
    private var emoji: String { sender == .yin ? "😇" : "😈" }
    private var alignment: Alignment { sender == .yin ? .leading : .trailing }

    var body: some View {
         HStack(alignment: .top, spacing: 4) {
             if sender == .yin {
                 EmojiView(emoji: emoji)
             } else {
                 Spacer()
             }

             TypingIndicatorView()

             if sender == .yang {
                 EmojiView(emoji: emoji)
             } else {
                 Spacer()
             }
         }
         .frame(maxWidth: .infinity)
    }
    
    private func EmojiView(emoji: String) -> some View {
        Text(emoji)
            .font(.system(size: 24))
            .padding(.top, 6)
    }
}

//#Preview {
//    VStack(alignment: .leading, spacing: 20) {
//        SingleChatBubbleView(message: OnboardingMessage(sender: .yin, text: "Hello from Yin! This is a slightly longer message to test wrapping."))
//        SingleChatBubbleView(message: OnboardingMessage(sender: .yang, text: "Yang here. Short and sweet."))
//        TypingBubbleView(sender: .yin)
//        TypingBubbleView(sender: .yang)
//    }
//    .padding()
//    .background(Color.gray.opacity(0.2))
//    .environment(\.themeColors, YTheme.Colors.light)
//} 
