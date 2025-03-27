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
    @State private var isAuthenticated = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView()
                    .environmentObject(authManager)
            } else if !isAuthenticated {
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
        isAuthenticated = Auth.auth().currentUser != nil
    }
}

#Preview {
    RootView()
}
