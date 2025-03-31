//
//  StreakViewModel.swift
//  y.lol
//
//  Created by Andrea Russo on 3/27/25.
//

import Foundation
import FirebaseFirestore

class StreakViewModel: ObservableObject {
    private let db = Firestore.firestore()
    @Published var isUpdating = false
    @Published var errorMessage = ""
    
    // Updates a user's streak if they've used the app today
    func updateUserStreak(userId: String, completion: @escaping (Bool) -> Void) {
        guard !userId.isEmpty else {
            self.errorMessage = "User ID is empty"
            completion(false)
            return
        }
        
        isUpdating = true
        errorMessage = ""
        
        // Get the user document reference
        let userRef = db.collection("users").document(userId)
        
        // First, fetch the current user data to check last activity
        userRef.getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            defer { self.isUpdating = false }
            
            if let error = error {
                self.errorMessage = "Error fetching user data: \(error.localizedDescription)"
                completion(false)
                return
            }
            
            guard let data = snapshot?.data() else {
                self.errorMessage = "User document not found"
                completion(false)
                return
            }
            
            // Get the last activity timestamp (if it exists)
            let lastActivity = data["lastActivity"] as? TimeInterval ?? 0
            let lastActivityDate = Date(timeIntervalSince1970: lastActivity)
            
            // Get current date components for comparison
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let lastActivityDay = calendar.startOfDay(for: lastActivityDate)
            
            // Update streak based on last activity
            var newStreak = data["streak"] as? Int ?? 1  // Default to 1 if no streak exists
            let daysSinceLastActivity = calendar.dateComponents([.day], from: lastActivityDay, to: today).day ?? 0
            
            if lastActivity == 0 {
                // First time using the app, keep streak at 1
                newStreak = 1
            } else if daysSinceLastActivity == 0 {
                // Already used the app today, streak remains the same
            } else if daysSinceLastActivity == 1 {
                // Used the app on consecutive days, increase streak
                newStreak += 1
            } else if daysSinceLastActivity > 1 {
                // Streak broken, reset to 1 (today's activity)
                newStreak = 1
            }
            
            // Update the user document with new streak and last activity
            userRef.updateData([
                "streak": newStreak,
                "lastActivity": Date().timeIntervalSince1970
            ]) { error in
                if let error = error {
                    self.errorMessage = "Error updating streak: \(error.localizedDescription)"
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }
}
