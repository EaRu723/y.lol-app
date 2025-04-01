import SwiftUI

struct SingleChatBubbleView: View {
    let message: OnboardingMessage
    
    var body: some View {
        // Convert OnboardingMessage to ChatMessage
        MessageView(
            message: ChatMessage(
                content: message.text,
                isUser: false, // AI messages in onboarding
                timestamp: Date(),
                imageUrl: nil
            ),
            index: 0,
            totalCount: 1,
            previousMessage: nil,
            nextMessage: nil,
            mode: message.sender == .yin ? .yin : .yang,
            onImageLoad: nil,
            showEmoji: true // Enable emoji display for onboarding
        )
    }
}

struct TypingBubbleView: View {
    let sender: Sender
    
    @Environment(\.themeColors) private var colors
    
    private var emoji: String { sender == .yin ? "😇" : "😈" }

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            Text(emoji)
                .font(.system(size: 24))
                .padding(.top, 6)
                .padding(.leading, 8)

            TypingIndicatorView()

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
