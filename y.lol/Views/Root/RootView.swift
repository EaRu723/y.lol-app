//
//  RootView.swift
//  y.lol
//
//  Created by Andrea Russo on 3/10/25.
//

import SwiftUI
import FirebaseAuth

struct RootView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var streakViewModel = StreakViewModel()
    @State private var isAuthenticated = false
//    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var hasUpdatedStreakThisSession = false
    
    var body: some View {
        Group {
            if !isAuthenticated {
                LoginView()
                    .environmentObject(authManager)
            } else {
                ChatView()
                    .environmentObject(authManager)
            }
        }
        .onAppear {
            checkAuthStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            checkAuthStatus()
        }
    }
    
    private func checkAuthStatus() {
        let wasAuthenticated = isAuthenticated
        isAuthenticated = Auth.auth().currentUser != nil
        
        // Only update streak once when the user logs in or app opens with logged in user
        if isAuthenticated && !hasUpdatedStreakThisSession {
            updateUserStreak()
            hasUpdatedStreakThisSession = true
        }
        
        // Reset the flag if the user logs out
        if !isAuthenticated && wasAuthenticated {
            hasUpdatedStreakThisSession = false
        }
    }
    
    private func updateUserStreak() {
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        
        streakViewModel.updateUserStreak(userId: userId) { success in
            if success {
                print("User streak updated successfully")
            } else {
                print("Failed to update user streak: \(streakViewModel.errorMessage)")
            }
        }
    }
}

#Preview {
    RootView()
}
