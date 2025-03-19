//
//  MessageView.swift
//  y.lol
//
//  Created by Andrea Russo on 3/11/25.
//

import SwiftUI

struct MessageView: View {
    @Environment(\.themeColors) private var colors
    let message: ChatMessage
    let index: Int
    let totalCount: Int
    
    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
            HStack {
                if message.isUser { Spacer() }
                
                Text(message.content)
                    .padding(12)
                    .background(message.isUser ? colors.userMessageBubble : colors.aiMessageBubble)
                    .foregroundColor(message.isUser ? colors.userMessageText : colors.aiMessageText)
                    .cornerRadius(16)
                
                if !message.isUser { Spacer() }
            }
            
            if let image = message.image {
                HStack {
                    if message.isUser { Spacer() }
                    
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 150)
                        .cornerRadius(12)
                    
                    if !message.isUser { Spacer() }
                }
                .padding(.horizontal)
            }
        }
        .padding(.horizontal)
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
