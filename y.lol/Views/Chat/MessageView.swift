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
    
    private var textColor: Color {
        colorScheme == .light ?
            Color(hex: "2C2C2C").opacity(message.isUser ? 0.9 : 0.75) :
            Color(hex: "F5F2E9").opacity(message.isUser ? 0.9 : 0.75)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Show 'Y' label only for non-user messages
            if !message.isUser {
                Text("Y")
                    .font(.system(size: 10, weight: .medium, design: .serif))
                    .foregroundColor(Color(hex: "2C2C2C").opacity(0.4))
                    .padding(.bottom, 4)
            }
            
            // Message content with appropriate styling
            Text(message.content)
                .font(.system(
                    size: message.isUser ? 16 : 14,
                    weight: message.isUser ? .regular : .light,
                    design: .serif
                ))
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            
            // Timestamp
            Text(formatTimestamp(message.timestamp))
                .font(.system(size: 8, weight: .light))
                .foregroundColor(Color(hex: "2C2C2C").opacity(0.3))
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
    
    /// Formats the timestamp to display only the time
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
