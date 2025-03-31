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
    var chatMode: FirebaseManager.ChatMode
    
    enum CodingKeys: String, CodingKey {
        case id, messages, timestamp, chatMode
    }
    
    // Add coding methods to handle the enum
    init(id: String, messages: [ChatMessage], timestamp: Date, chatMode: FirebaseManager.ChatMode) {
        self.id = id
        self.messages = messages
        self.timestamp = timestamp
        self.chatMode = chatMode
    }
    
    // Add encoder/decoder to properly handle the chatMode enum
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        messages = try container.decode([ChatMessage].self, forKey: .messages)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        
        // Decode the chat mode
        let modeString = try container.decode(String.self, forKey: .chatMode)
        chatMode = modeString == "yin" ? .yin : .yang
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(messages, forKey: .messages)
        try container.encode(timestamp, forKey: .timestamp)
        
        // Encode the chat mode as a string
        let modeString = chatMode == .yin ? "yin" : "yang"
        try container.encode(modeString, forKey: .chatMode)
    }
}
