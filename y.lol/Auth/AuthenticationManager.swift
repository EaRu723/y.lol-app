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
    private var tokenRefreshTask: Task<Void, Never>?
    
    init() {
        // Start token refresh cycle when initialized
        refreshTokenPeriodically()
    }
    
    func refreshTokenPeriodically() {
        tokenRefreshTask?.cancel()
        tokenRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await self?.refreshIdToken()
                try? await Task.sleep(nanoseconds: 45 * 60 * 1_000_000_000) // Refresh every 45 minutes
            }
        }
    }
    
    func refreshIdToken() async throws {
        print("Debug - Starting token refresh")
        guard let currentUser = Auth.auth().currentUser else {
            print("Debug - No current user found")
            idToken = nil
            throw URLError(.badServerResponse)
        }
        
        let token = try await currentUser.getIDToken()
        
        await MainActor.run {
            self.idToken = token
            print("Debug - Successfully got new token: \(String(describing: token.prefix(20)))...")
        }
    }
    
    func getAuthenticatedUser() throws -> User {
        guard let user = Auth.auth().currentUser else {
            throw URLError(.badServerResponse)
        }
        
        return User(from: user)
    }
        
    func signOut() throws {
        tokenRefreshTask?.cancel()
        tokenRefreshTask = nil
        idToken = nil
        try Auth.auth().signOut()
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
        // Get and store the Firebase ID token
        try await refreshIdToken()
        
        await insertUserRecord(user: user)
        return user
    }


    private func insertUserRecord(user: User) async {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.id)
        
        // Attempt to fetch the existing user document
        do {
            let document = try await userRef.getDocument()
            if document.exists {
                // If the document exists, update the user data without the `joined` property
                var userData = user.asDictionary()
                userData.removeValue(forKey: "joined") // Remove `joined` to avoid updating it
                try await userRef.setData(userData, merge: true)
            } else {
                // If the document does not exist, set the user data including `joined`
                try await userRef.setData(user.asDictionary(), merge: true)
            }
            print("User document successfully written or updated!")
        } catch let error {
            print("Error accessing user document: \(error.localizedDescription)")
        }
    }
}
