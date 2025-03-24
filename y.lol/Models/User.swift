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
    var streak: Int = 0
    
    
    func asDictionary(includeScores: Bool = false) -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "name": name,
            "email": email,
            "joined": joined,
            "streak": streak
        ]
        
        if let dob = dateOfBirth {
            dict["dateOfBirth"] = dob
        }
        
        if let vibe = vibe {
            dict["vibe"] = vibe
        }
        
        return dict
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
