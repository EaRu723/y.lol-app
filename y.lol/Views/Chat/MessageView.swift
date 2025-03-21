//
//  MessageView.swift
//  y.lol
//
//  Created by Andrea Russo on 3/11/25.
//

import SwiftUI

struct MessageView: View {
    @Environment(\.colorScheme) private var colorScheme
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
                    .background(getBubbleBackgroundColor())
                    .foregroundColor(getBubbleTextColor())
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(getBubbleBorderColor(), lineWidth: 0.5)
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
    
    // Dynamic colors based on dark/light mode and sender
    private func getBubbleBackgroundColor() -> Color {
        if message.isUser {
            return colorScheme == .dark ? .white : .black
        } else {
            return colorScheme == .dark ? .black : .white
        }
    }
    
    private func getBubbleTextColor() -> Color {
        if message.isUser {
            return colorScheme == .dark ? .black : .white
        } else {
            return colorScheme == .dark ? .white : .black
        }
    }
    
    private func getBubbleBorderColor() -> Color {
        if message.isUser {
            return .clear
        } else {
            return colorScheme == .dark ? Color.gray.opacity(0.5) : Color.gray.opacity(0.3)
        }
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
