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
    
    // Update properties to use optional previous/next messages
    private var isFirstInGroup: Bool {
        guard let previous = previousMessage else { return true }
        return previous.isUser != message.isUser
    }
    
    private var isLastInGroup: Bool {
        guard let next = nextMessage else { return true }
        return next.isUser != message.isUser
    }
    
    private var bubbleShape: some Shape {
        BubbleShape(
            isUser: message.isUser,
            isFirstInGroup: isFirstInGroup,
            isLastInGroup: isLastInGroup
        )
    }
    
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
        HStack(spacing: 0) {
            if message.isUser {
                Spacer(minLength: 40)
            }
            
            // Message bubble
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(textColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(bubbleBackground)
                    .clipShape(bubbleShape)
                    .overlay(
                        bubbleShape
                            .stroke(!message.isUser ? getBorderColor() : Color.clear, lineWidth: 1)
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
            .padding(.vertical, isFirstInGroup ? 4 : 1)
            
            if !message.isUser {
                Spacer(minLength: 40)
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

// Add custom bubble shape
struct BubbleShape: Shape {
    let isUser: Bool
    let isFirstInGroup: Bool
    let isLastInGroup: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius: CGFloat = 16
        let tailRadius: CGFloat = 4
        let tailOffset: CGFloat = 6
        
        // Start from top-left
        path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
        
        // Top edge
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        
        // Top-right corner
        path.addArc(
            center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
            radius: radius,
            startAngle: Angle(degrees: -90),
            endAngle: Angle(degrees: 0),
            clockwise: false
        )
        
        // Right edge
        if isUser && isLastInGroup {
            // Add tail on right for user messages
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius - tailOffset))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX + tailRadius, y: rect.maxY - tailOffset),
                control: CGPoint(x: rect.maxX, y: rect.maxY - tailOffset)
            )
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.maxY - tailOffset + tailRadius),
                control: CGPoint(x: rect.maxX + tailRadius, y: rect.maxY - tailOffset)
            )
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        
        // Bottom-right corner
        path.addArc(
            center: CGPoint(x: rect.maxX - radius, y: rect.maxY - radius),
            radius: radius,
            startAngle: Angle(degrees: 0),
            endAngle: Angle(degrees: 90),
            clockwise: false
        )
        
        // Bottom edge
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        
        // Bottom-left corner
        path.addArc(
            center: CGPoint(x: rect.minX + radius, y: rect.maxY - radius),
            radius: radius,
            startAngle: Angle(degrees: 90),
            endAngle: Angle(degrees: 180),
            clockwise: false
        )
        
        // Left edge
        if !isUser && isLastInGroup {
            // Add tail on left for AI messages
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - radius - tailOffset))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX - tailRadius, y: rect.maxY - tailOffset),
                control: CGPoint(x: rect.minX, y: rect.maxY - tailOffset)
            )
            path.addQuadCurve(
                to: CGPoint(x: rect.minX, y: rect.maxY - tailOffset + tailRadius),
                control: CGPoint(x: rect.minX - tailRadius, y: rect.maxY - tailOffset)
            )
        }
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        
        // Top-left corner
        path.addArc(
            center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
            radius: radius,
            startAngle: Angle(degrees: 180),
            endAngle: Angle(degrees: 270),
            clockwise: false
        )
        
        path.closeSubpath()
        return path
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
                mode: .yin
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
                mode: .yang
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

