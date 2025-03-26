//
//  MediaItem.swift
//  y.lol
//
//  Created by Andrea Russo on 3/26/25.
//

import Foundation
import LinkPresentation

// Represents external content (links, images, etc.)
struct MediaContent: Codable, Identifiable {
    let id: String
    let type: MediaType
    let url: String
    var metadata: MediaMetadata?
    var timestamp: TimeInterval
    
    enum MediaType: String, Codable {
        case link
        case image
        case video
    }
}

// Separate metadata structure since LPLinkMetadata isn't Codable
struct MediaMetadata: Codable {
    let title: String?
    let description: String?
    let imageUrl: String?
    let siteName: String?
}
