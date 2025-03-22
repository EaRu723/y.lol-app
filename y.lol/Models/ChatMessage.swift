//
//  ChatMessage.swift
//  y.lol
//
//  Created by Andrea Russo on 3/11/25.
//

import Foundation
import UIKit
import SwiftUI

// Message model
struct ChatMessage: Identifiable, Codable {
    var id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
    var imageUrl: String? = nil
    
    // Non-persistent UI state (won't be stored)
    var image: UIImage? = nil
    
    // Coding keys for proper serialization
    enum CodingKeys: String, CodingKey {
        case id, content, isUser, timestamp, imageUrl
    }
    
    // Initializer for messages with an image
    init(content: String, isUser: Bool, timestamp: Date, image: UIImage?) {
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.image = image
    }
    
    // Initializer for messages with an image URL
    init(content: String, isUser: Bool, timestamp: Date, imageUrl: String?) {
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.imageUrl = imageUrl
    }
}

