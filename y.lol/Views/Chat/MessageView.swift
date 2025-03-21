//
//  MessageView.swift
//  y.lol
//
//  Created by Andrea Russo on 3/11/25.
//

import SwiftUI

struct MessageView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.themeColors) private var colors
    let message: ChatMessage
    let index: Int
    let totalCount: Int
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                // Message text
                Text(message.content)
                    .padding(10)
                    .background(message.isUser ? colors.userMessageBubble : colors.aiMessageBubble)
                    .foregroundColor(message.isUser ? colors.userMessageText : colors.aiMessageText)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(colors.text(opacity: 0.1), lineWidth: 0.5)
                    )
                
                // Image if present
                if let image = message.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: 200, maxHeight: 200)
                        .cornerRadius(12)
                        .clipped()
                }
            }
            
            if !message.isUser {
                Spacer()
            }
        }
        .padding(.horizontal)
    }
    
    private func getBubbleBorderColor() -> Color {
        return colors.text(opacity: 0.1)
    }
}

// Preview provider
struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            MessageView(
                message: ChatMessage(
                    content: "Hello, how are you?",
                    isUser: true,
                    timestamp: Date()
                ),
                index: 0,
                totalCount: 2
            )
            
            MessageView(
                message: ChatMessage(
                    content: "I'm doing well, thank you for asking. How can I help you today?",
                    isUser: false,
                    timestamp: Date()
                ),
                index: 1,
                totalCount: 2
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
