import SwiftUI

struct OnboardingPageView: View {
    let yinText: String
    let yangText: String
    let buttonText: String
    let hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle
    let isLastPage: Bool
    let showSignInButton: Bool
    let onContinue: (() -> Void)?
    let onSignIn: (() -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.themeColors) private var colors
    @State private var displayedYinText = ""
    @State private var displayedYangText = ""
    @State private var isYinTyping = false
    @State private var isYangTyping = false
    @State private var showYinMessage = false
    @State private var showYangMessage = false
    
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
            
            // Chat-style messages with typing animations
            OnboardingChatBubbleView(
                yinText: displayedYinText,
                yangText: displayedYangText,
                isYinTyping: isYinTyping,
                isYangTyping: isYangTyping,
                showYinMessage: showYinMessage,
                showYangMessage: showYangMessage
            )
            .frame(height: 120)
            
            Spacer()
            
            // Action button
            if showSignInButton {
                // Sign in button
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
                // Continue button
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
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(colors.accent.opacity(0.01))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(colors.text, lineWidth: 1)
                    )
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
        .onChange(of: yinText) { _ in
            startTypingAnimation()
        }
        .onChange(of: yangText) { _ in
            startTypingAnimation() 
        }
    }
    
    private func startTypingAnimation() {
        // Reset all animation states
        displayedYinText = ""
        displayedYangText = ""
        showYinMessage = false
        showYangMessage = false
        
        // Begin with Yin typing animation
        isYinTyping = true
        
        // After a short "typing" period, show the Yin message
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isYinTyping = false
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showYinMessage = true
                displayedYinText = yinText
            }
            
            // After Yin message appears, start Yang typing
            if !yangText.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    isYangTyping = true
                    
                    // After a short "typing" period, show the Yang message
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        isYangTyping = false
                        
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showYangMessage = true
                            displayedYangText = yangText
                        }
                        
                        // Provide haptic feedback when both animations complete
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            let generator = UIImpactFeedbackGenerator(style: hapticStyle)
                            generator.impactOccurred()
                        }
                    }
                }
            } else {
                // If no Yang message, provide haptic feedback after Yin animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    let generator = UIImpactFeedbackGenerator(style: hapticStyle)
                    generator.impactOccurred()
                }
            }
        }
    }
}

#Preview {
    OnboardingPageView(
        yinText: "welcome to a space of balance",
        yangText: "where opposites can coexist",
        buttonText: "Continue", 
        hapticStyle: .light,
        isLastPage: false,
        showSignInButton: false,
        onContinue: {},
        onSignIn: nil
    )
    .padding()
    .background(Color(.systemBackground))
} 
