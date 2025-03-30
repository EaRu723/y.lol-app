//
//  OnboardingView.swift
//  y.lol
//
//  Created by Andrea Russo on 3/11/25.
//

import Foundation
import SwiftUI
import FirebaseAuth

struct OnboardingView: View {
    @Binding var isPresented: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.themeColors) private var colors
    @AppStorage("welcomeShown") private var hasCompletedOnboarding = true
    
    @StateObject private var authManager = AuthenticationManager.shared
    private let signInAppleHelper = SignInAppleHelper()
    
    @State private var registrationComplete = false
    @State private var isSignedIn = false
    @State private var currentPage = 0
    @State private var handle: String = ""
    @State private var isClaimingHandle: Bool = false
    @State private var claimError: String? = nil
    
    // Update onboardingPages data structure to use the 'messages' array
    private var onboardingPages: [OnboardingPage] {
        return [
            // Page 1: Sign In
            OnboardingPage(
                messages: [ // Use the 'messages' parameter
                    .init(sender: .yin, text: "hi, welcome to Y. so glad you're here."), // Create OnboardingMessage instances
                    .init(sender: .yang, text: "yooooo sup, nice to meet u fr"),
                    .init(sender: .yin, text: "let's get you signed in.")
                ],
                buttonText: "Sign in with Apple",
                hapticStyle: .light
            ),
            // Page 2: Handle Claim
            OnboardingPage(
                messages: [ // Use the 'messages' parameter
                    .init(sender: .yin, text: "what should we call you?"),
                    .init(sender: .yang, text: "pick a handle that represents you")
                    // You can add more messages here if desired, e.g.:
                    // .init(sender: .yang, text: "make it cool.")
                ],
                buttonText: "Claim Handle",
                hapticStyle: .medium
            ),
            // Page 3: Get Started
            OnboardingPage(
                messages: [ // Use the 'messages' parameter
                    .init(sender: .yin, text: "embrace the duality"),
                    .init(sender: .yang, text: "let's begin")
                ],
                buttonText: "Get Started",
                hapticStyle: .heavy
            )
        ]
    }
    
    var body: some View {
        ZStack {
            colors.backgroundWithNoise
                .ignoresSafeArea()
            
            VStack {
                onboardingTabView
            }
        }
        .interactiveDismissDisabled(!registrationComplete)
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var onboardingTabView: some View {
        TabView(selection: $currentPage) {
            // First page
            pageView(for: 0)
            
            // Second page
            pageView(for: 1)
            
            // Last page
            pageView(for: 2)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        .highPriorityGesture(DragGesture())
    }
    
    private func pageView(for index: Int) -> some View {
        let page = onboardingPages[index]
        let isLastPage = index == onboardingPages.count - 1
        let showSignInButton = index == 0
        let showHandleInput = index == 1
        
        return OnboardingPageView(
            index: index,
            currentPage: $currentPage, messages: page.messages,
            buttonText: page.buttonText,
            hapticStyle: page.hapticStyle,
            isLastPage: isLastPage,
            showSignInButton: showSignInButton,
            showHandleInput: showHandleInput,
            onContinue: {
                Task {
                    if showHandleInput {
                        isClaimingHandle = true
                        claimError = nil
                        do {
                            try await claimHandle()
                            await MainActor.run {
                                withAnimation {
                                    currentPage = index + 1
                                }
                                isClaimingHandle = false
                            }
                        } catch {
                            await MainActor.run {
                                claimError = "Failed to claim handle: \(error.localizedDescription)"
                                isClaimingHandle = false
                            }
                        }
                    } else {
                        await MainActor.run {
                            withAnimation {
                                if isLastPage {
                                    hasCompletedOnboarding = true
                                    registrationComplete = true
                                    isPresented = false
                                } else {
                                    currentPage = index + 1
                                }
                            }
                        }
                    }
                }
            },
            onSignIn: showSignInButton ? handleSignIn : nil,
            onBack: index > 0 ? {
                withAnimation {
                    currentPage = index - 1
                    claimError = nil
                }
            } : nil,
            handle: $handle,
            isClaimingHandle: $isClaimingHandle
        )
        .tag(index)
        .overlay(alignment: .bottom) {
             if isClaimingHandle && showHandleInput {
                 ProgressView()
                     .padding(.bottom, 120)
             } else if let error = claimError, showHandleInput {
                 Text(error)
                     .foregroundColor(.red)
                     .font(.caption)
                     .padding(.bottom, 120)
             }
        }
    }
    
    // MARK: - Actions
    
    private func handleSignIn() {
        Task {
            do {
                let tokens = try await signInAppleHelper.startSignInWithAppleFlow()
                try await authManager.signInWithApple(tokens: tokens)
                isSignedIn = true
                // Move to the next page instead of dismissing
                withAnimation {
                    currentPage = 1
                }
            } catch {
                print("Failed to sign in with Apple: \(error)")
            }
        }
    }
    
    private func claimHandle() async throws {
        guard !handle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NSError(domain: "OnboardingView", code: 1, userInfo: [NSLocalizedDescriptionKey: "Handle cannot be empty."])
        }
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_."))
        if handle.rangeOfCharacter(from: allowedCharacters.inverted) != nil {
             throw NSError(domain: "OnboardingView", code: 2, userInfo: [NSLocalizedDescriptionKey: "Handle can only contain letters, numbers, underscores, and periods."])
        }
        guard handle.count >= 3 else {
            throw NSError(domain: "OnboardingView", code: 3, userInfo: [NSLocalizedDescriptionKey: "Handle must be at least 3 characters long."])
        }

        guard let userId = Auth.auth().currentUser?.uid else {
            throw URLError(.userAuthenticationRequired)
        }
        let taken = try await authManager.isHandleTaken(handle)
        if taken {
            throw NSError(domain: "OnboardingView", code: 4, userInfo: [NSLocalizedDescriptionKey: "This handle is already taken."])
        }

        try await authManager.updateUserHandle(userId: userId, handle: handle)
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
} 
