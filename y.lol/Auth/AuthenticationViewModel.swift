//
//  AuthenticationViewModel.swift
//  y.lol
//
//  Created by Andrea Russo on 3/10/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

// For Sign in with Apple
import AuthenticationServices
import CryptoKit

enum AuthenticationState {
    case unauthenticated
    case authenticating
    case authenticated
}

enum AuthenticationFlow {
    case login
    case signUp
}

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    
    @Published var flow: AuthenticationFlow = .login
    
    @Published var isValid = false
    @Published var authenticationState: AuthenticationState = .unauthenticated
    @Published var errorMessage = ""
    @Published var user: User?
    @Published var displayName = ""
    
    private var currentNonce: String?
    
    init() {
        registerAuthStateHandler()
        verifySignInWithAppleAuthenticationState()
        
        $flow
            .combineLatest($email, $password, $confirmPassword)
            .map { flow, email, password, confirmPassword in
                flow == .login
                ? !(email.isEmpty || password.isEmpty)
                : !(email.isEmpty || password.isEmpty || confirmPassword.isEmpty)
            }
            .assign(to: &$isValid)
    }
    
    
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    
    
    func registerAuthStateHandler() {
        if authStateHandler == nil {
            authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] auth, firebaseUser in
                guard let self = self else { return }
                
                if let firebaseUser = firebaseUser {
                    // User is signed in
                    self.authenticationState = .authenticated
                    self.displayName = firebaseUser.displayName ?? "No Name"
                    
                    // Start token refresh cycle
                    AuthenticationManager.shared.refreshTokenPeriodically()
                } else {
                    // No user is signed in
                    self.authenticationState = .unauthenticated
                }
            }
        }
    }
    
    
    func switchFlow() {
        flow = flow == .login ? .signUp : .login
        errorMessage = ""
    }
    
    private func wait() async {
        do {
            print("Wait")
            try await Task.sleep(nanoseconds: 1_000_000_000)
            print("Done")
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    func reset() {
        flow = .login
        email = ""
        password = ""
        confirmPassword = ""
    }
}

// MARK: - Email and Password Authentication

extension AuthenticationViewModel {
    
    func fetchUser() {
        // Check if there is a logged in user
        guard let userID = Auth.auth().currentUser?.uid else {
            self.errorMessage = "No authenticated user found."
            return
        }
        
        // Access Firestore instance
        let db = Firestore.firestore()
        
        // Fetch user documents from Firestore.
        db.collection("users").document(userID).getDocument{ [weak self] snapshot, error in
            // Check for errors and validate data.
            guard let data = snapshot?.data(), error == nil else {
                return
            }
            
            // Pull scores from Firestore data
            let scores: [Score] = (data["scores"] as? [[String: Any]] ?? []).compactMap { dict in
                guard let score = dict["score"] as? Int,
                      let date = dict["date"] as? TimeInterval,
                      let hintsUsed = dict["hintsUsed"] as? Int else {
                    return nil
                }
                return Score(score: score, date: date, hintsUsed: hintsUsed)
            }
            
            // Update user object in the main thread
            DispatchQueue.main.async {
                self?.user = User(id: data["id"] as? String ?? "",
                                  name: data["name"] as? String ?? "",
                                  email: data["email"] as? String ?? "",
                                  joined: data["joined"] as? TimeInterval ?? 0,
                                  scores: scores
                )
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        }
        catch {
            print(error)
            errorMessage = error.localizedDescription
        }
    }
    
//    func deleteAccount(completion: @escaping (Bool) -> Void) async {
//        guard let firebaseUser = Auth.auth().currentUser else {
//            errorMessage = "No authenticated user found."
//            completion(false)
//            return
//        }
//
//        do {
//            try await firebaseUser.delete()
//            // After successful deletion, update the authentication state.
//            authenticationState = .unauthenticated
//            // Optionally reset other user data here
//            resetUserData()
//            // Inform the caller of success, so UI can react accordingly.
//            completion(true)
//        } catch {
//            errorMessage = error.localizedDescription
//            completion(false)
//        }
//    }
    
    private func resetUserData() {
        email = ""
        password = ""
        confirmPassword = ""
        user = nil
        displayName = ""
    }
}

// MARK: Sign in with Apple

extension AuthenticationViewModel {
    
    var isUserAuthenticated: Bool {
        return Auth.auth().currentUser != nil
    }
    
    func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
        let nonce = randomNonceString()
        currentNonce = nonce
        request.nonce = sha256(nonce)
    }
    
    func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        if case .failure(let failure) = result {
            errorMessage = failure.localizedDescription
        }
        else if case .success(let authorization) = result {
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                guard let nonce = currentNonce else {
                    fatalError("Invalid state: a login callback was received, but no login request was sent.")
                }
                guard let appleIDToken = appleIDCredential.identityToken else {
                    print("Unable to fetch identity token.")
                    return
                }
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                    return
                }
                
                let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                          idToken: idTokenString,
                                                          rawNonce: nonce)
                Task {
                    do {
                        let authResult = try await Auth.auth().signIn(with: credential)
                        await self.updateDisplayName(for: authResult.user, with: appleIDCredential)
                        
                        // Prepare the user model for Firestore update
                        let newUser = User(id: authResult.user.uid,
                                           name: self.displayName,
                                           email: authResult.user.email ?? "No Email",
                                           joined: Date().timeIntervalSince1970)
                        
                        self.updateUserInFirestore(user: newUser)
                    } catch {
                        print("Error authenticating: \(error.localizedDescription)")
                        self.errorMessage = "Authentication error: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    func updateDisplayName(for firebaseUser: FirebaseAuth.User, with appleIDCredential: ASAuthorizationAppleIDCredential, force: Bool = false) async {
        if let currentDisplayName = Auth.auth().currentUser?.displayName, !currentDisplayName.isEmpty {
            // current user is non-empty, don't overwrite it
        }
        else {
            let changeRequest = firebaseUser.createProfileChangeRequest()
            changeRequest.displayName = appleIDCredential.displayName()
            do {
                try await changeRequest.commitChanges()
                self.displayName = Auth.auth().currentUser?.displayName ?? ""
            }
            catch {
                print("Unable to update the user's displayname: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func verifySignInWithAppleAuthenticationState() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let providerData = Auth.auth().currentUser?.providerData
        if let appleProviderData = providerData?.first(where: { $0.providerID == "apple.com" }) {
            Task {
                do {
                    let credentialState = try await appleIDProvider.credentialState(forUserID: appleProviderData.uid)
                    switch credentialState {
                    case .authorized:
                        break // The Apple ID credential is valid.
                    case .revoked, .notFound:
                        // The Apple ID credential is either revoked or was not found, so show the sign-in UI.
                        self.signOut()
                    default:
                        break
                    }
                }
                catch {
                }
            }
        }
    }
    func updateUserInFirestore(user: User) {
        let db = Firestore.firestore()
        db.collection("users").document(user.id).setData(user.asDictionary(), merge: true) { error in
            if let error = error {
                print("Error writing document: \(error)")
                self.errorMessage = "Failed to update user data: \(error.localizedDescription)"
            } else {
                print("Document successfully written!")
            }
        }
    }
}

extension ASAuthorizationAppleIDCredential {
    func displayName() -> String {
        return [self.fullName?.givenName, self.fullName?.familyName]
            .compactMap( {$0})
            .joined(separator: " ")
    }
}

// Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: [Character] =
    Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length
    
    while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
            var random: UInt8 = 0
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if errorCode != errSecSuccess {
                fatalError(
                    "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
                )
            }
            return random
        }
        
        randoms.forEach { random in
            if remainingLength == 0 {
                return
            }
            
            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
    }
    
    return result
}

private func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    let hashString = hashedData.compactMap {
        String(format: "%02x", $0)
    }.joined()
    
    return hashString
}
