//
//  ChatMessage.swift
//  y.lol
//
//  Created by Andrea Russo on 3/11/25.
//

import Foundation
import UIKit
import SwiftUI
import LinkPresentation

// Message model
struct ChatMessage: Identifiable, Codable {
    var id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
    var media: [MediaContent]? = nil
    
    // Non-persistent UI state (won't be stored)
    var loadedMetadata: [String: LPLinkMetadata]? = nil
    
    // Coding keys for proper serialization
    enum CodingKeys: String, CodingKey {
        case id, content, isUser, timestamp, media
    }
    
    // Adding custom Codable implementation to handle UUID strings properly
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle id as either UUID or String
        if let idString = try? container.decode(String.self, forKey: .id) {
            self.id = UUID(uuidString: idString) ?? UUID()
        } else {
            self.id = try container.decode(UUID.self, forKey: .id)
        }
        
        self.content = try container.decode(String.self, forKey: .content)
        self.isUser = try container.decode(Bool.self, forKey: .isUser)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.media = try container.decodeIfPresent([MediaContent].self, forKey: .media)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id.uuidString, forKey: .id)  // Store ID as string
        try container.encode(content, forKey: .content)
        try container.encode(isUser, forKey: .isUser)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(media, forKey: .media)
    }
    
    // Basic initializer
    init(content: String, isUser: Bool, timestamp: Date, media: [MediaContent]? = nil) {
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.media = media
    }
    
    // Convenience initializer for messages with a single image
    init(content: String, isUser: Bool, timestamp: Date, image: UIImage?) {
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.media = nil // We don't store the UIImage directly anymore
    }
    
    // Convenience initializer for messages with a single image URL
    init(content: String, isUser: Bool, timestamp: Date, imageUrl: String?) {
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        if let url = imageUrl {
            self.media = [
                MediaContent(
                    id: UUID().uuidString,
                    type: .image,
                    url: url,
                    metadata: nil,
                    timestamp: Date().timeIntervalSince1970
                )
            ]
        } else {
            self.media = nil
        }
    }
}

