//
//  ProfileViewModel.swift
//  y.lol
//
//  Created by Andrea Russo on 3/24/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

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
    
    // Save status
    @Published var isSaving = false
    @Published var saveError = ""
    
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
                    
                    // Create user with data from Firestore
                    let user = User(
                        id: currentUser.id,
                        name: data["name"] as? String ?? currentUser.name,
                        email: data["email"] as? String ?? currentUser.email,
                        joined: data["joined"] as? TimeInterval ?? Date().timeIntervalSince1970,
                        dateOfBirth: dateOfBirth,
                        vibe: vibe,
                        streak: streak
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
        editedVibe = user.vibe ?? ""
        if let dobTimestamp = user.dateOfBirth {
            editedDateOfBirth = Date(timeIntervalSince1970: dobTimestamp)
        }
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
    
    func saveProfile() {
        guard let currentUser = user else { return }
        
        isSaving = true
        saveError = ""
        
        Task {
            do {
                let db = Firestore.firestore()
                let userRef = db.collection("users").document(currentUser.id)
                
                var updateData: [String: Any] = [
                    "name": editedName,
                    "vibe": editedVibe
                ]
                
                // Only update email through Firebase Auth if it changed
                if editedEmail != currentUser.email {
                    do {
                        try await Auth.auth().currentUser?.updateEmail(to: editedEmail)
                        updateData["email"] = editedEmail
                    } catch {
                        await MainActor.run {
                            saveError = "Failed to update email: \(error.localizedDescription)"
                            isSaving = false
                        }
                        return
                    }
                }
                
                // Add date of birth if provided
                if let dob = editedDateOfBirth {
                    updateData["dateOfBirth"] = dob.timeIntervalSince1970
                }
                
                try await userRef.updateData(updateData)
                
                // Refresh user data after update
                fetchUserData()
                
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
    }
    
    func formatDate(timestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
}
