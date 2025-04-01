//
//  ProfileView.swift
//  y.lol
//
//  Created on 3/11/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UIKit

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
                        .font(YTheme.Typography.title)
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
                        VStack(spacing: 12) {
                                if let url = user.profilePictureUrl {
                                    CachedAsyncImage(url: URL(string: url))
                                } else {
                                    Text(user.emoji ?? "☯️")
                                        .font(.system(size: 80))
                                }
                            }
                            
                            // User details
                            VStack(spacing: 12) {
                                if viewModel.isEditMode {
                                    EditProfileView(viewModel: viewModel)
                                } else {
                                    // Read-only handle (name removed)
                                    Text("@y.\(user.handle)") // Display handle with prefix
                                        .font(YTheme.Typography.title) // Use title font for handle
                                        .foregroundColor(colors.text)
                                        .padding(.bottom, 8) // Keep padding consistent
                                    
                                    // Streak and Score boxes
                                    VStack(spacing: 12) {
                                        // Streak Box
                                        HStack {
                                            Text("🔥")
                                                .font(.system(size: 24))
                                            Text("\(user.streak)")
                                                .font(YTheme.Typography.subtitle)
                                                .foregroundColor(colors.text)
                                        }
                                        HStack {
                                            if viewModel.isFetchingScores {
                                                ProgressView()
                                                    .scaleEffect(0.8)
                                                    .tint(colors.text)
                                            } else {
                                                HStack {
                                                    Text("😇")
                                                        .font(.system(size: 24))
                                                    Text("\(user.yinScore) %")
                                                        .font(YTheme.Typography.subtitle)
                                                        .foregroundColor(colors.text)
                                                }
                                                HStack {
                                                    Text("😈")
                                                        .font(.system(size: 24))
                                                    Text("\(user.yangScore) %")
                                                        .font(YTheme.Typography.subtitle)
                                                        .foregroundColor(colors.text)
                                                }
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .cornerRadius(12)
                                        
                                        if !viewModel.scoresError.isEmpty {
                                            Text(viewModel.scoresError)
                                                .font(YTheme.Typography.caption)
                                                .foregroundColor(.red)
                                                .padding(.top, 4)
                                        }
                                    }
                                    .padding(.top, 16)
                                    
                                    // Display vibe if available
                                    if let vibe = user.vibe, !vibe.isEmpty {
                                        VibeView(vibe: vibe, 
                                                 onShuffle: {
                                                     viewModel.generateNewVibe()
                                                 },
                                                 isLoading: viewModel.isGeneratingVibe)
                                        .padding(.top, 12)
                                        
                                        if !viewModel.vibeError.isEmpty {
                                            Text(viewModel.vibeError)
                                                .font(YTheme.Typography.caption)
                                                .foregroundColor(.red)
                                                .padding(.top, 4)
                                        }
                                    } else {
                                        VibeView(vibe: "", onShuffle: {
                                            viewModel.generateNewVibe()
                                        })
                                        .padding(.top, 12)
                                    }
                                }
                            }
                            .padding(.vertical, 20)
                            
                            
                            Spacer()
                            
                            // Share button
                            Button(action: {
                                shareProfile(user: user)
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share Profile")
                                        .font(YTheme.Typography.body)
                                }
                                .foregroundColor(colors.text)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(colors.accent.opacity(0.01))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(colors.text, lineWidth: 1)
                                )
                            }
                            .padding(.horizontal, YTheme.Spacing.large)
                            
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
                                    .foregroundColor(colors.text)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.red.opacity(0.1))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.red, lineWidth: 1)
                                    )
                                }
                                .padding(.horizontal, YTheme.Spacing.large)
                                .padding(.bottom, YTheme.Spacing.large)
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
            viewModel.fetchYinYangScores()
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
    
    private func shareProfile(user: User) {
        // Create a view to render for sharing
        let shareView = VStack(spacing: 20) {
            // Profile picture or emoji
            if let url = user.profilePictureUrl {
                CachedAsyncImage(url: URL(string: url))
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
            } else {
                Text(user.emoji ?? "☯️")
                    .font(.system(size: 80))
            }
            
            // Display Handle (Name removed) with prefix
            Text("@y.\(user.handle)") // Display handle with prefix
                .font(YTheme.Typography.title) // Use title font
                .foregroundColor(colors.text)
                .padding(.bottom, 4) // Add some padding below handle

            // Streak
            HStack {
                Text("🔥")
                    .font(.system(size: 24))
                Text("\(user.streak)")
                    .font(YTheme.Typography.subtitle)
                    .foregroundColor(colors.text)
            }
            
            // Scores
            HStack(spacing: 20) {
                HStack {
                    Text("😇")
                        .font(.system(size: 24))
                    Text("\(user.yinScore)%")
                        .font(YTheme.Typography.subtitle)
                        .foregroundColor(colors.text)
                }
                HStack {
                    Text("😈")
                        .font(.system(size: 24))
                    Text("\(user.yangScore)%")
                        .font(YTheme.Typography.subtitle)
                        .foregroundColor(colors.text)
                }
            }
            
            // Vibe if available
            if let vibe = user.vibe, !vibe.isEmpty {
                VibeView(vibe: vibe)
                    .frame(maxWidth: 300) // Limit width to force text wrapping
            }
        }
        .frame(width: 390) // Keep width fixed, remove height
        .padding(.horizontal, 20)
        .padding(.vertical, 20) // Reduce vertical padding
        .background(colors.backgroundWithNoise)
        
        // Convert view to UIImage
        let renderer = ImageRenderer(content: shareView)
        renderer.scale = 3.0 // Higher resolution
        
        // Ensure we're on the main thread
        DispatchQueue.main.async {
            if let uiImage = renderer.uiImage {
                // Share the image
                let activityVC = UIActivityViewController(
                    activityItems: [uiImage],
                    applicationActivities: nil
                )
                
                // Present the share sheet
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootVC = window.rootViewController {
                    activityVC.popoverPresentationController?.sourceView = window
                    rootVC.present(activityVC, animated: true)
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthenticationManager.shared)
        .withYTheme()
}
