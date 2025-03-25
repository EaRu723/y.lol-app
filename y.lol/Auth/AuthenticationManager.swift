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
            if document.exists {
                var userData = user.asDictionary()
                userData.removeValue(forKey: "joined")
                try await userRef.setData(userData, merge: true)
            } else {
                try await userRef.setData(user.asDictionary(), merge: true)
            }
            print("User document successfully written or updated!")
        } catch let error {
            print("Error accessing user document: \(error.localizedDescription)")
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
}
