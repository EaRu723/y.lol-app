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
    
    // Add computed properties for the missing variables
    private var textColor: Color {
        message.isUser ? colors.userMessageText : colors.aiMessageText
    }
    
    private var bubbleBackground: Color {
        message.isUser ? colors.userMessageBubble : colors.aiMessageBubble
    }
    
    private var formattedTimestamp: String {
        // Format the date as needed
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: message.timestamp)
    }
    
    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 2) {
            HStack {
                if !message.isUser {
                    // AI avatar if needed
                }
                
                // Message bubble
                VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(textColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(bubbleBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(getBubbleBorderColor(), lineWidth: 1)
                        )
                    
                    // Display media content if available
                    if let mediaItems = message.media {
                        ForEach(mediaItems) { mediaItem in
                            switch mediaItem.type {
                            case .image:
                                AsyncImage(url: URL(string: mediaItem.url)) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: 200, height: 150)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(maxWidth: 200, maxHeight: 200)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    case .failure:
                                        Image(systemName: "photo.fill")
                                            .foregroundColor(.gray)
                                            .frame(width: 200, height: 150)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            case .link:
                                // Link preview will be implemented later
                                Text(mediaItem.url)
                                    .foregroundColor(.blue)
                                    .underline()
                            case .video:
                                // Video preview will be implemented later
                                Text("Video content")
                            }
                        }
                    }
                }
                
                if message.isUser {
                    // User avatar if needed
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
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
                    timestamp: Date(),
                    imageUrl: "https://example.com/image.jpg"
                ),
                index: 0,
                totalCount: 2
            )
            
            MessageView(
                message: ChatMessage(
                    content: "I'm doing well, thank you for asking!",
                    isUser: false,
                    timestamp: Date(),
                    imageUrl: nil
                ),
                index: 1,
                totalCount: 2
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
