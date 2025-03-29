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

struct OnboardingPage {
    let text: String
    let buttonText: String
    let hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle
}

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
    
    // Add this property to track if registration is complete
    @State private var registrationComplete = false
    
    @State private var currentPage = 0
    
    private let pages = [
        OnboardingPage(text: "hi", buttonText: "Continue", hapticStyle: .light),
        OnboardingPage(text: "you could be anywhere right now \n\n but you're here", buttonText: "Next", hapticStyle: .medium),
        OnboardingPage(text: "Y", buttonText: "Sign in with Apple", hapticStyle: .heavy)
    ]
    
    var body: some View {
        ZStack {
            colors.backgroundWithNoise
                .ignoresSafeArea()
            
            VStack {
                #if DEBUG
                HStack {
                    Spacer()
                    Button(action: { showingDebugMenu = true }) {
                        Image(systemName: "gear")
                            .font(.system(size: 20))
                            .foregroundColor(colors.text.opacity(0.5))
                    }
                    .padding()
                }
                #endif
                
                TabView(selection: $currentPage) {
                    // First page
                    OnboardingPageView(
                        text: pages[0].text,
                        buttonText: pages[0].buttonText,
                        hapticStyle: pages[0].hapticStyle,
                        isLastPage: false,
                        onContinue: {
                            withAnimation {
                                currentPage = 1
                            }
                        },
                        onSignIn: nil
                    )
                    .tag(0)
                    
                    // Second page
                    OnboardingPageView(
                        text: pages[1].text,
                        buttonText: pages[1].buttonText,
                        hapticStyle: pages[1].hapticStyle,
                        isLastPage: false,
                        onContinue: {
                            withAnimation {
                                currentPage = 2
                            }
                        },
                        onSignIn: nil
                    )
                    .tag(1)
                    
                    // Last page
                    OnboardingPageView(
                        text: pages[2].text,
                        buttonText: pages[2].buttonText,
                        hapticStyle: pages[2].hapticStyle,
                        isLastPage: true,
                        onContinue: nil,
                        onSignIn: {
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
                    )
                    .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                .gesture(DragGesture())
            }
            
            #if DEBUG
            .sheet(isPresented: $showingDebugMenu) {
                NavigationView {
                    List {
                        Section(header: Text("Onboarding Debug Controls")) {
                            Button("Reset Onboarding") {
                                stateManager.resetOnboarding()
                                showingDebugMenu = false
                            }
                            
                            Button("Skip to Page 1") {
                                showingDebugMenu = false
                            }
                            
                            Button("Skip to Page 2") {
                                showingDebugMenu = false
                            }
                            
                            Button("Skip to Final Page") {
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
        .interactiveDismissDisabled(!registrationComplete)
    }
}

struct OnboardingPageView: View {
    let text: String
    let buttonText: String
    let hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle
    let isLastPage: Bool
    let onContinue: (() -> Void)?
    let onSignIn: (() -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.themeColors) private var colors
    @State private var displayedText = ""
    @State private var isTyping = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            SimplifiedYinYangView(
                size: 100,
                lightColor: colorScheme == .light ? .white : YTheme.Colors.parchmentDark,
                darkColor: colorScheme == .light ? YTheme.Colors.textLight : YTheme.Colors.textDark
            )
            .rotationEffect(.degrees(90))
            
            Spacer()
            
            Text(displayedText)
                .font(YTheme.Typography.serif(size: 18, weight: .light))
                .foregroundColor(colors.text)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .frame(height: 80)
            
            Spacer()
            
            if isLastPage {
                // Use SignInWithAppleButtonView for the last page
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: hapticStyle)
                    generator.impactOccurred()
                    onSignIn?()
                }) {
                    SignInWithAppleButtonView(
                        type: .signIn,
                        style: colorScheme == .dark ? .white : .black,
                        cornerRadius: 10
                    )
                    .frame(height: 50)
                }
                .frame(width: 250)
                .padding(.horizontal, YTheme.Spacing.large)
            } else {
                // Regular button for other pages
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: hapticStyle)
                    generator.impactOccurred()
                    onContinue?()
                }) {
                    HStack {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 20))
                        
                        Text(buttonText)
                            .font(YTheme.Typography.body)
                    }
                    .foregroundColor(colors.text)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(buttonBackground)
                    .overlay(buttonBorder)
                }
                .fixedSize(horizontal: true, vertical: false)
                .frame(maxWidth: 250)
                .padding(.horizontal, YTheme.Spacing.large)
            }
            
            Spacer().frame(height: 40)
        }
        .onAppear {
            startTypingAnimation()
        }
        .onChange(of: text) { _ in
            startTypingAnimation()
        }
    }
    
    @ViewBuilder
    private var buttonBackground: some View {
        if isLastPage {
            ZStack {
                if colorScheme == .dark {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white)
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black)
                }
            }
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(colors.accent.opacity(0.01))
        }
    }
    
    @ViewBuilder
    private var buttonBorder: some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(
                isLastPage ? 
                    (colorScheme == .dark ? Color.white : Color.black) : 
                    colors.text, 
                lineWidth: 1
            )
    }
    
    private func startTypingAnimation() {
        displayedText = ""
        isTyping = true
        
        var charIndex = 0
        
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if charIndex < text.count {
                displayedText += String(text[text.index(text.startIndex, offsetBy: charIndex)])
                charIndex += 1
            } else {
                timer.invalidate()
                isTyping = false
                
                // Provide haptic feedback when text animation completes
                let generator = UIImpactFeedbackGenerator(style: hapticStyle)
                generator.impactOccurred()
            }
        }
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}
