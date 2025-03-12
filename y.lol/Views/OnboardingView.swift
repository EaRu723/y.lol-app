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
    
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
    }
}
#endif

struct OnboardingPage {
    let text: String
    let hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle
}

struct OnboardingView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @State private var displayedText = ""
    @State private var isTyping = false
    
    #if DEBUG
    @StateObject private var stateManager = OnboardingStateManager.shared
    @State private var showingDebugMenu = false
    #endif
    
    private let pages = [
        OnboardingPage(text: "hi", hapticStyle: .light),
        OnboardingPage(text: "you could be anywhere right now \n\n but you're here", hapticStyle: .medium),
        OnboardingPage(text: "Y", hapticStyle: .heavy)
    ]
    
    private var colors: (background: Color, text: Color) {
        switch colorScheme {
        case .light:
            return (
                background: Color(hex: "F5F2E9"),
                text: Color(hex: "2C2C2C")
            )
        case .dark:
            return (
                background: Color(hex: "1C1C1E"),
                text: Color(hex: "F5F2E9")
            )
        @unknown default:
            return (
                background: Color(hex: "F5F2E9"),
                text: Color(hex: "2C2C2C")
            )
        }
    }
    
    var body: some View {
        ZStack {
            colors.background
                .overlay(
                    Color.primary
                        .opacity(0.03)
                        .blendMode(.multiply)
                )
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                #if DEBUG
                // Debug controls - only visible in development
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
                Spacer()
                // Yin Yang symbol
                SimplifiedYinYangView(
                    size: 100,
                    lightColor: colorScheme == .light ? .white : Color(hex: "1C1C1E"),
                    darkColor: colorScheme == .light ? Color(hex: "2C2C2C") : Color(hex: "F5F2E9")
                )
                .rotationEffect(.degrees(90))
                Spacer()
                // Animated text
                Text(displayedText)
                    .font(.system(size: 18, weight: .light, design: .serif))
                    .foregroundColor(colors.text)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .frame(height: 80)
                
                Spacer()
                
                // Navigation buttons
                if currentPage == pages.count - 1 {
                    // Sign in with Apple button on last page
                    Button(action: {
                        withAnimation {
                            hasCompletedOnboarding = true
                        }
                    }) {
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
                } else {
                    Button(action: nextPage) {
                        Text("Continue")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(colors.text)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(colors.text.opacity(0.1))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 40)
                }
                
                Spacer().frame(height: 40)
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
                                currentPage = 0
                                startTypingAnimation()
                                showingDebugMenu = false
                            }
                            
                            Button("Skip to Page 2") {
                                currentPage = 1
                                startTypingAnimation()
                                showingDebugMenu = false
                            }
                            
                            Button("Skip to Final Page") {
                                currentPage = pages.count - 1
                                startTypingAnimation()
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
        .onAppear {
            startTypingAnimation()
        }
    }
    
    private func nextPage() {
        let generator = UIImpactFeedbackGenerator(style: pages[currentPage].hapticStyle)
        generator.impactOccurred()
        
        withAnimation {
            currentPage += 1
        }
        startTypingAnimation()
    }
    
    private func startTypingAnimation() {
        displayedText = ""
        isTyping = true
        
        let text = pages[currentPage].text
        var charIndex = 0
        
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if charIndex < text.count {
                displayedText += String(text[text.index(text.startIndex, offsetBy: charIndex)])
                charIndex += 1
            } else {
                timer.invalidate()
                isTyping = false
            }
        }
    }
}

#Preview {
    OnboardingView()
}
