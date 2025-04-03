//
//  User.swift
//  y.lol
//
//  Created by Andrea Russo on 3/10/25.
//

import Foundation
import FirebaseAuth

struct User: Codable {
    let id: String
    let name: String
    let email: String
    let joined: TimeInterval
    var handle: String
    var dateOfBirth: TimeInterval?
    
    // Updated scores from backend
    var streak: Int = 0
    var yinScore: Int = 50  // Default to 50%
    var yangScore: Int = 50  // Default to 50%
    var vibe: String?
    var vibeSummary: String?
    var emoji: String?
    var media: [MediaContent] = []
    var profilePictureUrl: String?
    
    
    // Computed property for backward compatibility
    var score: Int {
        return yinScore
    }
    
    func asDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "name": name,
            "email": email,
            "joined": joined,
            "handle": handle,
            "streak": streak,
            "score": score
        ]
        
        // Optional fields
        if let dob = dateOfBirth { dict["dateOfBirth"] = dob }
        if let vibe = vibe { dict["vibe"] = vibe }
        if let vibeSummary = vibeSummary { dict["vibeSummary"] = vibeSummary }
        if let emoji = emoji { dict["emoji"] = emoji }
        if !media.isEmpty { dict["media"] = media }
        if let profilePictureUrl = profilePictureUrl { dict["profilePictureUrl"] = profilePictureUrl }
        
        return dict
    }
}


extension User {
    init(from firebaseUser: FirebaseAuth.User) {
        self.id = firebaseUser.uid
        self.name = firebaseUser.displayName ?? "Unknown"
        self.email = firebaseUser.email ?? "No email"
        self.joined = Date().timeIntervalSince1970
        // Initialize new required properties
        self.handle = "@" + (firebaseUser.displayName?.lowercased().replacingOccurrences(of: " ", with: "") ?? "user")
        self.streak = 1  // Start with streak of 1 for new users
        self.yinScore = 50
        self.yangScore = 50
        self.media = []
    }
}
