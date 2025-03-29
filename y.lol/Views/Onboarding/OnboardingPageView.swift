import SwiftUI

struct OnboardingPageView: View {
    let yinText: String
    let yangText: String
    let buttonText: String
    let hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle
    let isLastPage: Bool
    let onContinue: (() -> Void)?
    let onSignIn: (() -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.themeColors) private var colors
    @State private var displayedYinText = ""
    @State private var displayedYangText = ""
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
            
            // Chat-style messages
            OnboardingChatBubbleView(
                yinText: displayedYinText,
                yangText: displayedYangText
            )
            .frame(height: 120)
            
            Spacer()
            
            // Action button
            if isLastPage {
                // Sign in button for the last page
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
                // Continue button for other pages
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
        displayedYinText = ""
        displayedYangText = ""
        isTyping = true
        
        // Animate yin text first
        animateText(text: yinText, into: \Self.displayedYinText) { 
            // Then animate yang text
            animateText(text: yangText, into: \Self.displayedYangText) {
                isTyping = false
                // Provide haptic feedback when both text animations complete
                let generator = UIImpactFeedbackGenerator(style: hapticStyle)
                generator.impactOccurred()
            }
        }
    }
    
    private func animateText(text: String, into keyPath: ReferenceWritableKeyPath<OnboardingPageView, String>, completion: @escaping () -> Void) {
        var charIndex = 0
        
        if text.isEmpty {
            completion()
            return
        }
        
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if charIndex < text.count {
                self[keyPath: keyPath] += String(text[text.index(text.startIndex, offsetBy: charIndex)])
                charIndex += 1
            } else {
                timer.invalidate()
                completion()
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
        onContinue: {},
        onSignIn: nil
    )
    .padding()
    .background(Color(.systemBackground))
} 
