//
//  ChatMessage.swift
//  y.lol
//
//  Created by Andrea Russo on 3/11/25.
//

import Foundation
// Message model
struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
}
