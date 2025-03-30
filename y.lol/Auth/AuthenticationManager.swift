//
//  AuthenticationManager.swift
//  y.lol
//
//  Created by Andrea Russo on 3/10/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class AuthenticationManager: ObservableObject {
    
    static let shared = AuthenticationManager()
    
    @Published private(set) var idToken: String?
    @Published var tokenError: Error?
    @Published var hasTokenError: Bool = false
    private var tokenRefreshTask: Task<Void, Never>?
    private var isRefreshing: Bool = false
    private var refreshAttempts: Int = 0
    private let maxRefreshAttempts = 2
    
    init() {
        // Start token refresh cycle when initialized
        refreshTokenPeriodically()
        // Get initial token
        Task {
            try? await refreshIdToken()
        }
    }
    
    func refreshTokenPeriodically() {
        tokenRefreshTask?.cancel()
        tokenRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    try await self?.refreshIdToken()
                    try await Task.sleep(nanoseconds: 30 * 60 * 1_000_000_000) // Refresh every 30 minutes
                } catch {
                    print("Periodic token refresh failed: \(error.localizedDescription)")
                    try? await Task.sleep(nanoseconds: 1 * 60 * 1_000_000_000) // Wait 1 minute before retry
                }
            }
        }
    }

    func validateToken() async -> Bool {
        // Reset attempts if this is a new validation cycle
        if !isRefreshing {
            refreshAttempts = 0
            isRefreshing = true
        }
        
        defer {
            if refreshAttempts >= maxRefreshAttempts {
                isRefreshing = false
                refreshAttempts = 0
            }
        }
        
        guard refreshAttempts < maxRefreshAttempts else {
            print("Exceeded max refresh attempts, requiring login")
            await MainActor.run { self.hasTokenError = true }
            return false
        }
        
        do {
            guard let user = Auth.auth().currentUser else {
                print("No authenticated user")
                await MainActor.run { 
                    self.hasTokenError = true
                    self.idToken = nil
                }
                return false
            }
            
            let token = try await user.getIDToken(forcingRefresh: refreshAttempts > 0)
            await MainActor.run {
                self.idToken = token
                self.hasTokenError = false
                self.tokenError = nil
            }
            isRefreshing = false
            return true
            
        } catch {
            print("Token validation failed (attempt \(refreshAttempts + 1)): \(error.localizedDescription)")
            refreshAttempts += 1
            
            if refreshAttempts >= maxRefreshAttempts {
                await MainActor.run { 
                    self.hasTokenError = true
                    self.idToken = nil
                }
                return false
            }
            
            // Try again with forced refresh
            return await validateToken()
        }
    }
    
    func refreshIdToken() async throws {
        print("Debug - Starting token refresh")
        guard let currentUser = Auth.auth().currentUser else {
            print("Debug - No current user found")
            await MainActor.run {
                self.idToken = nil
                self.tokenError = URLError(.userAuthenticationRequired)
                self.hasTokenError = true
            }
            throw URLError(.userAuthenticationRequired)
        }
        
        do {
            let token = try await currentUser.getIDToken(forcingRefresh: true)
            await MainActor.run {
                self.idToken = token
                self.tokenError = nil
                self.hasTokenError = false
                print("Debug - Successfully got new token")
            }
        } catch {
            print("Debug - Token refresh failed: \(error.localizedDescription)")
            await MainActor.run {
                self.idToken = nil
                self.tokenError = error
                self.hasTokenError = true
            }
            throw error
        }
    }

    func getAuthenticatedUser() throws -> User {
        guard let user = Auth.auth().currentUser else {
            throw URLError(.badServerResponse)
        }
        return User(from: user)
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            hasTokenError = false
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }

    func delete() async throws {
        guard let user = Auth.auth().currentUser else {
            throw URLError(.badURL)
        }
        try await user.delete()
    }

    @discardableResult
    func signInWithApple(tokens: SignInWithAppleResult) async throws -> User {
        print("Debug - Starting Apple Sign In")
        let credential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: tokens.token,
            rawNonce: tokens.nonce
        )
        let authResult = try await Auth.auth().signIn(with: credential)
        let user = User(from: authResult.user)
        
        print("Debug - Successfully signed in with Apple, attempting to refresh token")
        try await refreshIdToken()
        await insertUserRecord(user: user)
        return user
    }

    private func insertUserRecord(user: User) async {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.id)

        do {
            let document = try await userRef.getDocument()
            var userData = user.asDictionary() // Contains the default handle from User(from:)

            if document.exists {
                // Document exists (returning user). Merge updates,
                // but explicitly remove 'joined' and 'handle' from the data being merged
                // to preserve the original joined date and existing handle in Firestore.
                userData.removeValue(forKey: "joined")
                userData.removeValue(forKey: "handle")
            } else {
                // Document doesn't exist (new user).
                // Remove the default handle generated by User(from:).
                // The user will set their actual handle in the next onboarding step.
                userData.removeValue(forKey: "handle")
                // Keep the 'joined' date for the new user document.
            }

            // Use setData with merge true.
            // For existing docs: merges fields from `userData` (without joined/handle).
            // For new docs: creates doc with fields from `userData` (without handle, but with joined).
            try await userRef.setData(userData, merge: true)

            print("User document successfully written or updated!")
        } catch let error {
            // Consider more robust error handling or rethrowing if needed upstream
            print("Error accessing/updating user document in insertUserRecord: \(error.localizedDescription)")
        }
    }

    func refreshTokenAndRetry<T>(retryBlock: @escaping () async throws -> T) async throws -> T {
        print("Debug - Starting token refresh and retry")
        // Try to refresh the token
        do {
            try await refreshIdToken()
            print("Debug - Token refresh successful, retrying request")
            return try await retryBlock()
        } catch {
            print("Debug - Token refresh failed in retry: \(error.localizedDescription)")
            throw NSError(domain: "AuthError", code: 401, 
                         userInfo: [NSLocalizedDescriptionKey: "Failed to refresh authentication token: \(error.localizedDescription)"])
        }
    }

    // New function to check if handle is taken
    func isHandleTaken(_ handle: String) async throws -> Bool {
        let db = Firestore.firestore()
        let usersRef = db.collection("users")

        // Query for users with the specified handle
        let query = usersRef.whereField("handle", isEqualTo: handle).limit(to: 1)

        do {
            let snapshot = try await query.getDocuments()
            return !snapshot.isEmpty // If snapshot is not empty, the handle is taken
        } catch {
            print("Error checking if handle is taken: \(error.localizedDescription)")
            throw error // Re-throw the error to be handled by the caller
        }
    }

    // New function to update the user's handle
    func updateUserHandle(userId: String, handle: String) async throws {
        // 1. Check if handle is already taken
        let taken = try await isHandleTaken(handle)
        guard !taken else {
            // You might want a specific error type for this
            throw NSError(domain: "AuthError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Handle '\(handle)' is already taken."])
        }

        // 2. Proceed with update if handle is not taken
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)

        do {
            // Update only the handle field
            try await userRef.updateData(["handle": handle])
            print("Successfully updated handle for user \(userId) to \(handle)")

            // Optional: Refresh local user data if you store it beyond the User object
            // try await refreshUserDataLocally()

        } catch {
            print("Error updating handle for user \(userId): \(error.localizedDescription)")
            // Re-throw the error to be handled by the UI
            throw error
        }
    }
}
