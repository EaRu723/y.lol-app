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
    let previousMessage: ChatMessage?
    let nextMessage: ChatMessage?
    let mode: FirebaseManager.ChatMode
    let onImageLoad: (() -> Void)?
    let showEmoji: Bool
    
    // Update properties to use optional previous/next messages
    private var isFirstInGroup: Bool {
        guard let previous = previousMessage else { return true }
        return previous.isUser != message.isUser
    }
    
    private var isLastInGroup: Bool {
        guard let next = nextMessage else { return true }
        return next.isUser != message.isUser
    }
    
    // Add computed properties for the missing variables
    private var textColor: Color {
        message.isUser ? colors.userMessageText : colors.aiMessageText
    }
    
    private var bubbleBackground: Color {
        message.isUser ? colors.userMessageBubble : Color.gray.opacity(0.1)
    }
    
    private var formattedTimestamp: String {
        // Format the date as needed
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: message.timestamp)
    }
    
    // Add computed property for emoji
    private var emoji: String? {
        guard showEmoji else { return nil }
        return message.isUser ? nil : (mode == .yin ? "😇" : "😈")
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if message.isUser {
                Spacer(minLength: 40)
            } else if let emoji = emoji {
                // Show emoji for AI messages when enabled
                Text(emoji)
                    .font(.system(size: 24))
                    .padding(.top, 6)
                    .padding(.leading, 8)
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
                            .stroke(Color.clear, lineWidth: 1)
                    )
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.67, alignment: message.isUser ? .trailing : .leading)
                    .fixedSize(horizontal: false, vertical: true)
                
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
                                        .onAppear {
                                            print("Image loaded, triggering onImageLoad callback for message ID: \(message.id)")
                                            onImageLoad?()
                                        }
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
            
            if !message.isUser {
                Spacer(minLength: emoji != nil ? 32 : 40)
            }
        }
        .padding(.horizontal, 8)
    }
    
    private func getBorderColor() -> Color {
        switch mode {
        case .yin:
            return Color.blue.opacity(0.1)
        case .yang:
            return Color.red.opacity(0.1)
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
                    timestamp: Date(),
                    imageUrl: "https://example.com/image.jpg"
                ),
                index: 0,
                totalCount: 2,
                previousMessage: nil,
                nextMessage: ChatMessage(
                    content: "I'm doing well, thank you for asking!",
                    isUser: false,
                    timestamp: Date(),
                    imageUrl: nil
                ),
                mode: .yin,
                onImageLoad: nil,
                showEmoji: false
            )
            
            MessageView(
                message: ChatMessage(
                    content: "I'm doing well, thank you for asking!",
                    isUser: false,
                    timestamp: Date(),
                    imageUrl: nil
                ),
                index: 1,
                totalCount: 2,
                previousMessage: ChatMessage(
                    content: "Hello, how are you?",
                    isUser: true,
                    timestamp: Date(),
                    imageUrl: "https://example.com/image.jpg"
                ),
                nextMessage: nil,
                mode: .yang,
                onImageLoad: nil,
                showEmoji: false
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

