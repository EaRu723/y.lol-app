//
//  OnboardingView.swift
//  y.lol
//
//  Created by Andrea Russo on 3/11/25.
//

import Foundation
import SwiftUI

#if DEBUG
// Development helper to manage onboarding state
class OnboardingStateManager: ObservableObject {
    static let shared = OnboardingStateManager()
    
    @AppStorage("welcomeShown") var hasCompletedOnboarding = true
    
    func resetOnboarding() {
        hasCompletedOnboarding = true
    }
}
#endif

struct OnboardingView: View {
    @Binding var isPresented: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.themeColors) private var colors
    @AppStorage("welcomeShown") private var hasCompletedOnboarding = true
    
    #if DEBUG
    @StateObject private var stateManager = OnboardingStateManager.shared
    @State private var showingDebugMenu = false
    #endif
    
    @StateObject private var authManager = AuthenticationManager.shared
    private let signInAppleHelper = SignInAppleHelper()
    
    @State private var registrationComplete = false
    @State private var currentPage = 0
    
    // Move content creation to a separate function
    private var onboardingPages: [OnboardingPage] {
        return [
            OnboardingPage(
                yinText: "welcome to a space of balance",
                yangText: "where opposites can coexist",
                buttonText: "Continue", 
                hapticStyle: .light
            ),
            OnboardingPage(
                yinText: "you could be anywhere right now",
                yangText: "but you chose to be here",
                buttonText: "Next", 
                hapticStyle: .medium
            ),
            OnboardingPage(
                yinText: "embrace the duality",
                yangText: "sign in to begin",
                buttonText: "Sign in with Apple", 
                hapticStyle: .heavy
            )
        ]
    }
    
    var body: some View {
        ZStack {
            colors.backgroundWithNoise
                .ignoresSafeArea()
            
            VStack {
                #if DEBUG
                debugControls
                #endif
                
                onboardingTabView
            }
        }
        .interactiveDismissDisabled(!registrationComplete)
        #if DEBUG
        .sheet(isPresented: $showingDebugMenu) {
            debugMenuView
        }
        #endif
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
        .gesture(DragGesture())
    }
    
    private func pageView(for index: Int) -> some View {
        let page = onboardingPages[index]
        let isLastPage = index == onboardingPages.count - 1
        
        return OnboardingPageView(
            yinText: page.yinText,
            yangText: page.yangText,
            buttonText: page.buttonText,
            hapticStyle: page.hapticStyle,
            isLastPage: isLastPage,
            onContinue: isLastPage ? nil : {
                withAnimation {
                    currentPage = index + 1
                }
            },
            onSignIn: isLastPage ? handleSignIn : nil
        )
        .tag(index)
    }
    
    // MARK: - Actions
    
    private func handleSignIn() {
        Task {
            do {
                let tokens = try await signInAppleHelper.startSignInWithAppleFlow()
                try await authManager.signInWithApple(tokens: tokens)
                withAnimation {
                    hasCompletedOnboarding = true
                    registrationComplete = true
                    isPresented = false
                }
            } catch {
                print("Failed to sign in with Apple: \(error)")
            }
        }
    }
    
    // MARK: - Debug UI
    
    #if DEBUG
    @ViewBuilder
    private var debugControls: some View {
        HStack {
            Spacer()
            Button(action: { showingDebugMenu = true }) {
                Image(systemName: "gear")
                    .font(.system(size: 20))
                    .foregroundColor(colors.text.opacity(0.5))
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private var debugMenuView: some View {
        NavigationView {
            List {
                Section(header: Text("Onboarding Debug Controls")) {
                    Button("Reset Onboarding") {
                        stateManager.resetOnboarding()
                        showingDebugMenu = false
                    }
                    
                    Button("Skip to Page 1") {
                        currentPage = 0
                        showingDebugMenu = false
                    }
                    
                    Button("Skip to Page 2") {
                        currentPage = 1
                        showingDebugMenu = false
                    }
                    
                    Button("Skip to Final Page") {
                        currentPage = 2
                        showingDebugMenu = false
                    }
                }
            }
            .navigationTitle("Debug Menu")
            .navigationBarItems(trailing: Button("Done") {
                showingDebugMenu = false
            })
        }
    }
    #endif
}

#Preview {
    OnboardingView(isPresented: .constant(true))
} 