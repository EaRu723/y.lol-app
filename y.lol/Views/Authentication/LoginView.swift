//
//  LoginView.swift
//  y.lol
//
//  Created on 3/10/25.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var authHelper = SignInAppleHelper()
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    // Replace custom colors with theme
    private var colors: YTheme.Colors.Dynamic {
        YTheme.Colors.dynamic
    }
    
    var body: some View {
        ZStack {
            // Background
            colors.backgroundWithNoise
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Logo
                YinYangLogoView(
                    size: 80,
                    isLoading: isLoading,
                    lightColor: colorScheme == .light ? .white : YTheme.Colors.parchmentDark,
                    darkColor: colorScheme == .light ? YTheme.Colors.textLight : YTheme.Colors.textDark
                )
                
                Text("Y")
                    .font(YTheme.Typography.serif(size: 24, weight: .light))
                    .foregroundColor(colors.text)
                
                Spacer().frame(height: 40)
                
                // Sign in with Apple button
                Button(action: signInWithApple) {
                    HStack {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 20))
                        Text("Sign in with Apple")
                            .font(.system(size: 18, weight: .medium))
                    }
                    .foregroundColor(colorScheme == .dark ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(colorScheme == .dark ? Color.white : Color.black)
                    .cornerRadius(10)
                }
                .padding(.horizontal, 40)
                .buttonStyle(PlainButtonStyle())
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(YTheme.Typography.regular(size: 12))
                        .foregroundColor(.red)
                        .padding()
                }
                
                Spacer()
            }
            .padding()
            .disabled(isLoading)
            
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(colors.text)
            }
        }
    }
    
    func signInWithApple() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let result = try await authHelper.startSignInWithAppleFlow()
                try await authManager.signInWithApple(tokens: result)
                isLoading = false
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Sign in failed: \(error.localizedDescription)"
                    print("Sign in with Apple error: \(error)")
                }
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthenticationManager.shared)
}
