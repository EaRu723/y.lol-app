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
                // Display image if present
                if let image = message.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 250, maxHeight: 250)
                        .cornerRadius(12)
                        .padding(.vertical, 4)
                }
                
                // Display text if not empty
                if !message.content.isEmpty {
                    Text(message.content)
                        .padding()
                        .background(message.isUser ? colors.userMessageBubble : colors.aiMessageBubble)
                        .foregroundColor(message.isUser ? colors.userMessageText : colors.aiMessageText)
                        .cornerRadius(12)
                }
                
                // Timestamp
                Text(formatTimestamp(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(colors.text(opacity: 0.5))
                    .padding(.horizontal, 4)
            }
            
            if !message.isUser {
                Spacer()
            }
        }
        .padding(.horizontal)
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
           

// To preview this view, you can add this preview provider
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
