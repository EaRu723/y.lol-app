//
//  ProfileView.swift
//  y.lol
//
//  Created on 3/11/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var showingLogoutAlert = false
    @State private var user: User?
    @State private var isLoading = true
    @State private var errorMessage = ""
    
    // Colors based on color scheme
    private var colors: (background: Color, text: Color, accent: Color) {
        switch colorScheme {
        case .light:
            return (
                background: Color(hex: "F5F2E9"),    // light parchment
                text: Color(hex: "2C2C2C"),          // dark gray
                accent: Color(hex: "E4D5B7")         // warm beige
            )
        case .dark:
            return (
                background: Color(hex: "1C1C1E"),    // dark background
                text: Color(hex: "F5F2E9"),          // light text
                accent: Color(hex: "B8A179")         // darker warm accent
            )
        @unknown default:
            return (
                background: Color(hex: "F5F2E9"),
                text: Color(hex: "2C2C2C"),
                accent: Color(hex: "E4D5B7")
            )
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            colors.background
                .overlay(
                    Color.primary
                        .opacity(0.03)
                        .blendMode(.multiply)
                )
                .ignoresSafeArea()
            
            VStack {
                // Header
                HStack {
                    Button(action: {
                        // Dismiss this view
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20))
                            .foregroundColor(colors.text)
                    }
                    
                    Spacer()
                    
                    Text("Profile")
                        .font(.system(size: 20, weight: .light, design: .serif))
                        .foregroundColor(colors.text)
                    
                    Spacer()
                    
                    // Empty view for balance
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20))
                        .foregroundColor(.clear)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 20)
                
                if isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(colors.text)
                    Spacer()
                } else if let user = user {
                    // User info
                    VStack(spacing: 30) {
                        // Profile icon
                        YinYangLogoView(
                            size: 80,
                            isLoading: false,
                            lightColor: colorScheme == .light ? .white : Color(hex: "1C1C1E"),
                            darkColor: colorScheme == .light ? Color(hex: "2C2C2C") : Color(hex: "F5F2E9")
                        )
                        
                        // User details
                        VStack(spacing: 12) {
                            Text(user.name)
                                .font(.system(size: 24, weight: .medium, design: .serif))
                                .foregroundColor(colors.text)
                            
                            Text(user.email)
                                .font(.system(size: 16, weight: .light, design: .serif))
                                .foregroundColor(colors.text.opacity(0.7))
                            
                            Text("Joined \(formatDate(timestamp: user.joined))")
                                .font(.system(size: 14, weight: .light, design: .serif))
                                .foregroundColor(colors.text.opacity(0.5))
                                .padding(.top, 8)
                        }
                        .padding(.vertical, 20)
                        
                        // Stats section
                        if !user.scores.isEmpty {
                            VStack(spacing: 16) {
                                Text("Activity")
                                    .font(.system(size: 18, weight: .medium, design: .serif))
                                    .foregroundColor(colors.text)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                HStack(spacing: 20) {
                                    StatCard(
                                        title: "Total Sessions",
                                        value: "\(user.scores.count)",
                                        icon: "calendar",
                                        colors: colors
                                    )
                                    
                                    StatCard(
                                        title: "Best Score",
                                        value: "\(getBestScore(scores: user.scores))",
                                        icon: "star.fill",
                                        colors: colors
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer()
                        
                        // Logout button
                        Button(action: {
                            showingLogoutAlert = true
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Sign Out")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 20)
                        .alert(isPresented: $showingLogoutAlert) {
                            Alert(
                                title: Text("Sign Out"),
                                message: Text("Are you sure you want to sign out?"),
                                primaryButton: .destructive(Text("Sign Out")) {
                                    signOut()
                                },
                                secondaryButton: .cancel()
                            )
                        }
                    }
                    .padding()
                } else {
                    // Error or no user state
                    VStack {
                        Spacer()
                        
                        Text(errorMessage.isEmpty ? "No user information available" : errorMessage)
                            .font(.system(size: 16, weight: .regular, design: .serif))
                            .foregroundColor(colors.text.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button("Try Again") {
                            fetchUserData()
                        }
                        .padding()
                        .background(colors.accent)
                        .foregroundColor(colors.text)
                        .cornerRadius(10)
                        
                        Spacer()
                    }
                }
            }
        }
        .onAppear {
            fetchUserData()
        }
    }
    
    private func fetchUserData() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let currentUser = try authManager.getAuthenticatedUser()
                
                // Access Firestore to get additional user data
                let db = Firestore.firestore()
                let docRef = db.collection("users").document(currentUser.id)
                
                let document = try await docRef.getDocument()
                
                if let data = document.data() {
                    // Extract scores if they exist
                    let scores: [Score] = (data["scores"] as? [[String: Any]] ?? []).compactMap { dict in
                        guard let score = dict["score"] as? Int,
                              let date = dict["date"] as? TimeInterval,
                              let hintsUsed = dict["hintsUsed"] as? Int else {
                            return nil
                        }
                        return Score(score: score, date: date, hintsUsed: hintsUsed)
                    }
                    
                    // Create user with data from Firestore
                    let user = User(
                        id: currentUser.id,
                        name: data["name"] as? String ?? currentUser.name,
                        email: data["email"] as? String ?? currentUser.email,
                        joined: data["joined"] as? TimeInterval ?? Date().timeIntervalSince1970,
                        scores: scores
                    )
                    
                    await MainActor.run {
                        self.user = user
                        isLoading = false
                    }
                } else {
                    // If document doesn't exist yet, use the basic user info
                    await MainActor.run {
                        self.user = currentUser
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load profile: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func signOut() {
        do {
            try authManager.signOut()
            // Dismiss the profile sheet after successful logout
            presentationMode.wrappedValue.dismiss()
            
            // Post a notification to refresh auth status
            NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        } catch {
            errorMessage = "Error signing out: \(error.localizedDescription)"
        }
    }
    
    private func formatDate(timestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func getBestScore(scores: [Score]) -> Int {
        guard !scores.isEmpty else { return 0 }
        return scores.min(by: { $0.score < $1.score })?.score ?? 0
    }
}

// Helper view for stats
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let colors: (background: Color, text: Color, accent: Color)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(colors.text.opacity(0.7))
                
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundColor(colors.text.opacity(0.7))
            }
            
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundColor(colors.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(colors.accent.opacity(0.3))
        .cornerRadius(12)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthenticationManager.shared)
}
