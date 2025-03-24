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
    var dateOfBirth: TimeInterval?
    var vibe: String?
    
    var scores: [Score] = []
    
    func asDictionary(includeScores: Bool = false) -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "name": name,
            "email": email,
            "joined": joined
        ]
        
        if let dob = dateOfBirth {
            dict["dateOfBirth"] = dob
        }
        
        if let vibe = vibe {
            dict["vibe"] = vibe
        }
        
        if includeScores {
            dict["scores"] = scores.map { $0.asDictionary() }
        }
        return dict
    }
}

struct Score: Codable {
    let score: Int // Time to finish puzzle
    let date: TimeInterval // Store date as TimeInterval to comply with Firestore
    let hintsUsed: Int // Hints used
    
    func asDictionary() -> [String: Any] {
        return [
            "score": score,
            "date": date,
            "hintsUsed": hintsUsed]
    }
}

extension User {
    init(from firebaseUser: FirebaseAuth.User) {
        self.id = firebaseUser.uid
        self.name = firebaseUser.displayName ?? "Unknown" // Adjust based on your needs
        self.email = firebaseUser.email ?? "No email"
        self.joined = Date().timeIntervalSince1970 // Example placeholder
    }
}
