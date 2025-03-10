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
            
            VStack(spacing: 30) {
                // Logo
                YinYangLogoView(
                    size: 80,
                    isLoading: isLoading,
                    lightColor: colorScheme == .light ? .white : Color(hex: "1C1C1E"),
                    darkColor: colorScheme == .light ? Color(hex: "2C2C2C") : Color(hex: "F5F2E9")
                )
                
                Text("y.lol")
                    .font(.system(size: 24, weight: .light, design: .serif))
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
                        .font(.caption)
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
