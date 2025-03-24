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
                        .font(.system(size: 20, weight: .light, design: .serif))
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
                                    // Editable name field
                                    VStack(alignment: .leading) {
                                        Text("Name")
                                            .font(YTheme.Typography.caption)
                                            .foregroundColor(colors.text(opacity: 0.7))
                                        
                                        TextField("Name", text: $viewModel.editedName)
                                            .font(YTheme.Typography.body)
                                            .padding()
                                            .background(colors.accent.opacity(0.2))
                                            .cornerRadius(8)
                                            .foregroundColor(colors.text)
                                    }
                                    .padding(.horizontal)
                                    
                                    // Editable email field
                                    VStack(alignment: .leading) {
                                        Text("Email")
                                            .font(YTheme.Typography.caption)
                                            .foregroundColor(colors.text(opacity: 0.7))
                                        
                                        TextField("Email", text: $viewModel.editedEmail)
                                            .font(YTheme.Typography.body)
                                            .padding()
                                            .background(colors.accent.opacity(0.2))
                                            .cornerRadius(8)
                                            .foregroundColor(colors.text)
                                            .keyboardType(.emailAddress)
                                            .autocapitalization(.none)
                                            .disableAutocorrection(true)
                                    }
                                    .padding(.horizontal)
                                    
                                    // Date of Birth picker
                                    VStack(alignment: .leading) {
                                        Text("Date of Birth")
                                            .font(YTheme.Typography.caption)
                                            .foregroundColor(colors.text(opacity: 0.7))
                                        
                                        DatePicker(
                                            "",
                                            selection: Binding(
                                                get: { viewModel.editedDateOfBirth ?? Date() },
                                                set: { viewModel.editedDateOfBirth = $0 }
                                            ),
                                            displayedComponents: .date
                                        )
                                        .labelsHidden()
                                        .padding()
                                        .background(colors.accent.opacity(0.2))
                                        .cornerRadius(8)
                                        .foregroundColor(colors.text)
                                    }
                                    .padding(.horizontal)
                                    
                                    // Save/Cancel buttons
                                    HStack {
                                        Button(action: {
                                            viewModel.cancelEdit()
                                        }) {
                                            Text("Cancel")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(colors.text)
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .background(colors.accent.opacity(0.3))
                                                .cornerRadius(10)
                                        }
                                        
                                        Button(action: {
                                            viewModel.saveProfile()
                                        }) {
                                            if viewModel.isSaving {
                                                ProgressView()
                                                    .tint(Color.white)
                                            } else {
                                                Text("Save")
                                                    .font(.system(size: 16, weight: .medium))
                                            }
                                        }
                                        .foregroundColor(Color.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(colors.accent)
                                        .cornerRadius(10)
                                        .disabled(viewModel.isSaving)
                                    }
                                    .padding(.horizontal)
                                    .padding(.top, 10)
                                    
                                    if !viewModel.saveError.isEmpty {
                                        Text(viewModel.saveError)
                                            .font(YTheme.Typography.caption)
                                            .foregroundColor(.red)
                                            .padding(.horizontal)
                                    }
                                } else {
                                    // Read-only name and email
                                    Text(user.name)
                                        .font(YTheme.Typography.title)
                                        .foregroundColor(colors.text)
                                    
                                    Text(user.email)
                                        .font(YTheme.Typography.body)
                                        .foregroundColor(colors.text(opacity: 0.7))
                                    
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
                            
                            // Stats section
                            if !user.scores.isEmpty && !viewModel.isEditMode {
                                VStack(spacing: 16) {
                                    Text("Activity")
                                        .font(YTheme.Typography.subtitle)
                                        .foregroundColor(colors.text)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    HStack(spacing: 20) {
                                        StatCard(
                                            title: "Total Sessions",
                                            value: "\(user.scores.count)",
                                            icon: "calendar"
                                        )
                                        
                                        StatCard(
                                            title: "Best Score",
                                            value: "\(viewModel.getBestScore(scores: user.scores))",
                                            icon: "star.fill"
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            Spacer()
                            
                            // Logout button (only show in non-edit mode)
                            if !viewModel.isEditMode {
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

// Helper view for stats
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    @Environment(\.themeColors) private var colors
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(colors.text(opacity: 0.7))
                
                Text(title)
                    .font(YTheme.Typography.caption)
                    .foregroundColor(colors.text(opacity: 0.7))
            }
            
            Text(value)
                .font(YTheme.Typography.subtitle)
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
        .withYTheme()
}
