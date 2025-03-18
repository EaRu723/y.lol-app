//
//  ChatMessage.swift
//  y.lol
//
//  Created by Andrea Russo on 3/11/25.
//

import Foundation
import UIKit

// Message model
struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
    var image: UIImage? = nil
    
    init(content: String, isUser: Bool, timestamp: Date, image: UIImage? = nil) {
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.image = image
    }
}

