//
//  ChatSession.swift
//  y.lol
//
//  Created by Arnav Surve on 3/28/25.
//

import Foundation

struct ChatSession: Identifiable, Codable {
    var id: String
    var messages: [ChatMessage]
    var timestamp: Date
}
