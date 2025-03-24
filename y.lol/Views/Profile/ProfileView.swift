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
                            viewModel.enterEditMode()
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
                            // Profile icon
                            YinYangLogoView(
                                size: 80,
                                isLoading: false,
                                lightColor: colorScheme == .light ? .white : YTheme.Colors.parchmentDark,
                                darkColor: colorScheme == .light ? YTheme.Colors.textLight : YTheme.Colors.textDark
                            )
                            
                            // User details
                            VStack(spacing: 12) {
                                if viewModel.isEditMode {
                                    EditProfileView(viewModel: viewModel)
                                } else {
                                    // Read-only name and email
                                    Text(user.name)
                                        .font(YTheme.Typography.title)
                                        .foregroundColor(colors.text)
                                    
                                    Text(user.email)
                                        .font(YTheme.Typography.body)
                                        .foregroundColor(colors.text(opacity: 0.7))
                                    
                                    // Display vibe if available
                                    if let vibe = user.vibe, !vibe.isEmpty {
                                        VibeView(vibe: vibe)
                                            .padding(.top, 4)
                                    }
                                    
                                    // Display date of birth if available
                                    if let dob = user.dateOfBirth {
                                        Text("Born: \(viewModel.formatDate(timestamp: dob))")
                                            .font(YTheme.Typography.caption)
                                            .foregroundColor(colors.text(opacity: 0.7))
                                    }
                                    
                                    Text("Joined \(viewModel.formatDate(timestamp: user.joined))")
                                        .font(YTheme.Typography.caption)
                                        .foregroundColor(colors.text(opacity: 0.5))
                                        .padding(.top, 8)
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
