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
    @Environment(\.themeColors) private var colors
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var authManager: AuthenticationManager
    @StateObject private var viewModel: ProfileViewModel
    @State private var showingLogoutAlert = false
    @State private var showEditProfile = false
    
    init() {
        _viewModel = StateObject(wrappedValue: ProfileViewModel(authManager: AuthenticationManager.shared))
    }
    
    var body: some View {
        ZStack {
            // Background
            colors.backgroundWithNoise
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
                        .font(YTheme.Typography.subtitle)
                        .foregroundColor(colors.text)
                    
                    Spacer()
                    
                    // Edit button
                    if !viewModel.isEditMode && viewModel.user != nil && !viewModel.isLoading {
                        Button(action: {
                            showEditProfile = true
                        }) {
                            Image(systemName: "pencil")
                                .font(.system(size: 20))
                                .foregroundColor(colors.text)
                        }
                    } else {
                        // Empty view for balance
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20))
                            .foregroundColor(.clear)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 20)
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(colors.text)
                    Spacer()
                } else if let user = viewModel.user {
                    ScrollView {
                        VStack(spacing: 30) {
                            // Replace YinYangLogoView with emoji
                            if viewModel.isEditMode {
                                Text(viewModel.editedEmoji)
                                    .font(.system(size: 80))
                            } else {
                                Text(user.emoji ?? "☯️")
                                    .font(.system(size: 80))
                            }
                            
                            // User details
                            VStack(spacing: 12) {
                                if viewModel.isEditMode {
                                    EditProfileView(viewModel: viewModel)
                                } else {
                                    // Read-only name
                                    Text(user.name)
                                        .font(YTheme.Typography.title)
                                        .foregroundColor(colors.text)
                                    
                                    // Streak and Score boxes
                                    VStack(spacing: 12) {
                                        // Streak Box
                                        HStack {
                                            Text("🔥")
                                                .font(.system(size: 24))
                                            Text("\(user.streak)")
                                                .font(YTheme.Typography.title)
                                                .foregroundColor(colors.text)
                                        }
                                        HStack {
                                            HStack {
                                            Text("😇")
                                                .font(.system(size: 24))
                                                Text("\(user.score)")
                                                .font(YTheme.Typography.title)
                                                .foregroundColor(colors.text)
                                            }
                                             HStack {
                                            Text("😈")
                                                .font(.system(size: 24))
                                                 Text("\(100 - (user.score))")
                                                .font(YTheme.Typography.title)
                                                .foregroundColor(colors.text)
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .cornerRadius(12)
                                        
                                    }
                                    .padding(.top, 16)
                                    
                                    // Display vibe if available
                                    if let vibe = user.vibe, !vibe.isEmpty {
                                        VibeView(vibe: vibe)
                                            .padding(.top, 12)
                                    }
                                }
                            }
                            .padding(.vertical, 20)
                            
                            
                            Spacer()
                            
                            // Logout button (only show in non-edit mode)
                            if !viewModel.isEditMode {
                                Button(action: {
                                    showingLogoutAlert = true
                                }) {
                                    HStack {
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                        Text("Sign Out")
                                            .font(YTheme.Typography.body)
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
                        }
                        .padding()
                    }
                } else {
                    // Error or no user state
                    VStack {
                        Spacer()
                        
                        Text(viewModel.errorMessage.isEmpty ? "No user information available" : viewModel.errorMessage)
                            .font(YTheme.Typography.body)
                            .foregroundColor(colors.text(opacity: 0.7))
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button("Try Again") {
                            viewModel.fetchUserData()
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
        .withYTheme()
        .navigationDestination(isPresented: $showEditProfile) {
            EditProfileView(viewModel: viewModel)
                .navigationBarHidden(true)
        }
        .onAppear {
            viewModel.fetchUserData()
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
            viewModel.errorMessage = "Error signing out: \(error.localizedDescription)"
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthenticationManager.shared)
        .withYTheme()
}
