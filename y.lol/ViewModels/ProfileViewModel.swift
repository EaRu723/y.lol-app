//
//  ProfileViewModel.swift
//  y.lol
//
//  Created by Andrea Russo on 3/24/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import UIKit

class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = true
    @Published var errorMessage = ""
    @Published var isEditMode = false
    
    // Editable fields
    @Published var editedName = ""
    @Published var editedEmail = ""
    @Published var editedDateOfBirth: Date?
    @Published var editedVibe = ""
    @Published var editedEmoji = "☯️" // Default to yin-yang since that's what we show initially
    @Published var editedHandle = ""
    
    // Save status
    @Published var isSaving = false
    @Published var saveError = ""
    
    @Published var selectedProfileImage: UIImage?
    @Published var profilePictureUrl: String?
    
    private let authManager: AuthenticationManager
    
    init(authManager: AuthenticationManager) {
        self.authManager = authManager
    }
    
    func fetchUserData() {
        Task { @MainActor in
            // Set loading state
            isLoading = true
            errorMessage = ""
            
            do {
                let currentUser = try authManager.getAuthenticatedUser()
                
                // Access Firestore to get additional user data
                let db = Firestore.firestore()
                let docRef = db.collection("users").document(currentUser.id)
                
                let document = try await docRef.getDocument()
                
                if let data = document.data() {
                    
                    // Get date of birth if available
                    let dateOfBirth = data["dateOfBirth"] as? TimeInterval
                    
                    // Get vibe if available
                    let vibe = data["vibe"] as? String
                    
                    // Get streak if available
                    let streak = data["streak"] as? Int ?? 0
                    
                    // Get emoji if available
                    let emoji = data["emoji"] as? String
                    
                    // Get handle if available
                    let handle = data["handle"] as? String ?? "@\(currentUser.name.lowercased().replacingOccurrences(of: " ", with: ""))"
                    
                    // Get profile picture URL if available
                    let profilePictureUrl = data["profilePictureUrl"] as? String
                    
                    // Create user with data from Firestore
                    let user = User(
                        id: currentUser.id,
                        name: data["name"] as? String ?? currentUser.name,
                        email: data["email"] as? String ?? currentUser.email,
                        joined: data["joined"] as? TimeInterval ?? Date().timeIntervalSince1970,
                        handle: handle,
                        dateOfBirth: dateOfBirth,
                        streak: streak,
                        vibe: vibe,
                        emoji: emoji,
                        profilePictureUrl: profilePictureUrl
                    )
                    
                    // All this code now runs on the main actor
                    self.user = user
                    self.setupEditableFields(from: user)
                    isLoading = false
                } else {
                    // If document doesn't exist yet, use the basic user info
                    self.user = currentUser
                    self.setupEditableFields(from: currentUser)
                    isLoading = false
                }
            } catch {
                errorMessage = "Failed to load profile: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    private func setupEditableFields(from user: User) {
        editedName = user.name
        editedEmail = user.email
        editedHandle = user.handle
        editedVibe = user.vibe ?? ""
        editedEmoji = user.emoji ?? "☯️"
        if let dobTimestamp = user.dateOfBirth {
            editedDateOfBirth = Date(timeIntervalSince1970: dobTimestamp)
        }
        profilePictureUrl = user.profilePictureUrl
    }
    
    func enterEditMode() {
        isEditMode = true
    }
    
    func cancelEdit() {
        if let user = user {
            setupEditableFields(from: user)
        }
        isEditMode = false
    }
    
    func saveProfile() async {
        guard let currentUser = user else { return }
        
        await MainActor.run {
            isSaving = true
            saveError = ""
        }
        
        do {
            let db = Firestore.firestore()
            let userRef = db.collection("users").document(currentUser.id)
            
            var updateData: [String: Any] = [
                "name": editedName,
                "handle": editedHandle,
                "vibe": editedVibe,
                "emoji": editedEmoji,
                // Always include profilePictureUrl in the update, even if nil
                "profilePictureUrl": profilePictureUrl as Any
            ]
            
            // Only update email through Firebase Auth if it changed
            if editedEmail != currentUser.email {
                // Validate email format first
                guard isValidEmail(editedEmail) else {
                    await MainActor.run {
                        saveError = "Please enter a valid email address"
                        isSaving = false
                    }
                    return
                }
                
                updateData["email"] = editedEmail
            }
            
            // Add date of birth if provided
            if let dob = editedDateOfBirth {
                updateData["dateOfBirth"] = dob.timeIntervalSince1970
            }
            
            try await userRef.updateData(updateData)
            
            // Refresh user data after update
            await fetchUserData()
            
            await MainActor.run {
                isEditMode = false
                isSaving = false
            }
        } catch {
            await MainActor.run {
                saveError = "Failed to save profile: \(error.localizedDescription)"
                isSaving = false
            }
        }
    }
    
    func formatDate(timestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // Basic email validation function
    func isValidEmail(_ email: String) -> Bool {
        // Check for basic email format: text@text.text
        let emailRegex = "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // Add handle validation function
    func isValidHandle(_ handle: String) -> Bool {
        // Handle should start with @ and contain only letters, numbers, and underscores
        let handleRegex = "^@[A-Za-z0-9_]{1,15}$"
        let handlePredicate = NSPredicate(format: "SELF MATCHES %@", handleRegex)
        return handlePredicate.evaluate(with: handle)
    }
}
