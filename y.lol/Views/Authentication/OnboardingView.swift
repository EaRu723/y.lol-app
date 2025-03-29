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
    
    private let pages = [
        OnboardingPage(text: "hi", hapticStyle: .light),
        OnboardingPage(text: "you could be anywhere right now \n\n but you're here", hapticStyle: .medium),
        OnboardingPage(text: "Y", hapticStyle: .heavy)
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
                
                TabView {
                    // First page
                    OnboardingPageView(
                        text: pages[0].text,
                        hapticStyle: pages[0].hapticStyle,
                        isLastPage: false,
                        onContinue: {} as (() -> Void)?,
                        onSignIn: {} as (() -> Void)?
                    )
                    
                    // Second page
                    OnboardingPageView(
                        text: pages[1].text,
                        hapticStyle: pages[1].hapticStyle,
                        isLastPage: false,
                        onContinue: {} as (() -> Void)?,
                        onSignIn: {} as (() -> Void)?
                    )
                    
                    // Last page
                    OnboardingPageView(
                        text: pages[2].text,
                        hapticStyle: pages[2].hapticStyle,
                        isLastPage: true,
                        onContinue: {} as (() -> Void)?,
                        onSignIn: {
                            Task {
                                do {
                                    let tokens = try await signInAppleHelper.startSignInWithAppleFlow()
                                    try await authManager.signInWithApple(tokens: tokens)
                                    withAnimation {
                                        hasCompletedOnboarding = true
                                        isPresented = false
                                    }
                                } catch {
                                    print("Failed to sign in with Apple: \(error)")
                                }
                            }
                        }
                    )
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
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
    }
}

struct OnboardingPageView: View {
    let text: String
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
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: hapticStyle)
                    generator.impactOccurred()
                    onSignIn?()
                }) {
                    HStack {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 20))
                        Text("Sign in with Apple")
                            .font(YTheme.Typography.regular(size: 18, weight: .medium))
                    }
                    .foregroundColor(colorScheme == .dark ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(colorScheme == .dark ? Color.white : Color.black)
                    .cornerRadius(10)
                }
                .padding(.horizontal, 40)
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
