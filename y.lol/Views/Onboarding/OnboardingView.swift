//
//  OnboardingView.swift
//  y.lol
//
//  Created by Andrea Russo on 3/11/25.
//

import Foundation
import SwiftUI

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
            messages: page.messages,
            buttonText: page.buttonText,
            hapticStyle: page.hapticStyle,
            isLastPage: isLastPage,
            showSignInButton: showSignInButton,
            showHandleInput: showHandleInput,
            onContinue: {
                withAnimation {
                    if isLastPage {
                        hasCompletedOnboarding = true
                        registrationComplete = true
                        isPresented = false
                    } else {
                        currentPage = index + 1
                    }
                }
            },
            onSignIn: showSignInButton ? handleSignIn : nil,
            onBack: index > 0 ? {
                withAnimation {
                    currentPage = index - 1
                }
            } : nil
        )
        .tag(index)
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
}

#Preview {
    OnboardingView(isPresented: .constant(true))
} 