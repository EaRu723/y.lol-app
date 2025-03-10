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
    
    init() { }
    
    func getAuthenticatedUser() throws -> User {
        guard let user = Auth.auth().currentUser else {
            throw URLError(.badServerResponse)
        }
        
        return User(from: user)
    }
        
    func signOut() throws {
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
        let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: tokens.token, rawNonce: tokens.nonce)
        let authResult = try await Auth.auth().signIn(with: credential)
        let user = User(from:authResult.user)
        
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
