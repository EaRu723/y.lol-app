import SwiftUI

struct OnboardingPageView: View {
    let text: String
    let yinText: String
    let yangText: String
    let buttonText: String
    let hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle
    let isLastPage: Bool
    let onContinue: (() -> Void)?
    let onSignIn: (() -> Void)?
    
    // Constructor that supports both text formats
    init(text: String, buttonText: String, hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle, isLastPage: Bool, onContinue: (() -> Void)?, onSignIn: (() -> Void)?) {
        self.text = text
        self.yinText = ""
        self.yangText = ""
        self.buttonText = buttonText
        self.hapticStyle = hapticStyle
        self.isLastPage = isLastPage
        self.onContinue = onContinue
        self.onSignIn = onSignIn
    }
    
    // New constructor for yin-yang text
    init(yinText: String, yangText: String, buttonText: String, hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle, isLastPage: Bool, onContinue: (() -> Void)?, onSignIn: (() -> Void)?) {
        self.text = ""
        self.yinText = yinText
        self.yangText = yangText
        self.buttonText = buttonText
        self.hapticStyle = hapticStyle
        self.isLastPage = isLastPage
        self.onContinue = onContinue
        self.onSignIn = onSignIn
    }
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.themeColors) private var colors
    @State private var displayedText = ""
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
            
            if !yinText.isEmpty && !yangText.isEmpty {
                // Use YinYangTextView when we have both yin and yang text
                OnboardingYinYangTextView(
                    yinText: displayedYinText,
                    yangText: displayedYangText,
                    textSize: 18,
                    spacing: 16
                )
                .frame(height: 80)
            } else {
                // Use regular Text view for backward compatibility
                Text(displayedText)
                    .font(YTheme.Typography.serif(size: 18, weight: .light))
                    .foregroundColor(colors.text)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .frame(height: 80)
            }
            
            Spacer()
            
            actionButton
            
            Spacer().frame(height: 40)
        }
        .onAppear {
            startTypingAnimation()
        }
        .onChange(of: text) { _ in
            startTypingAnimation()
        }
        .onChange(of: yinText) { _ in
            startTypingAnimation()
        }
        .onChange(of: yangText) { _ in
            startTypingAnimation() 
        }
    }
    
    @ViewBuilder
    private var actionButton: some View {
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
        // Reset display text
        displayedText = ""
        displayedYinText = ""
        displayedYangText = ""
        isTyping = true
        
        if !yinText.isEmpty && !yangText.isEmpty {
            // Animate yin text first, then yang text
            animateTypingSequence(texts: [yinText, yangText], 
                                  intoKeyPaths: [\Self.displayedYinText, \Self.displayedYangText])
        } else {
            // Original animation for single text
            animateTypingSequence(texts: [text], intoKeyPaths: [\Self.displayedText])
        }
    }
    
    private func animateTypingSequence(texts: [String], intoKeyPaths: [ReferenceWritableKeyPath<OnboardingPageView, String>]) {
        guard texts.count == intoKeyPaths.count, !texts.isEmpty else { return }
        
        func animateNextText(index: Int) {
            guard index < texts.count else {
                isTyping = false
                let generator = UIImpactFeedbackGenerator(style: hapticStyle)
                generator.impactOccurred()
                return
            }
            
            animateText(text: texts[index], into: intoKeyPaths[index]) {
                animateNextText(index: index + 1)
            }
        }
        
        // Start the animation sequence
        animateNextText(index: 0)
    }
    
    private func animateText(text: String, into keyPath: ReferenceWritableKeyPath<OnboardingPageView, String>, completion: @escaping () -> Void) {
        var charIndex = 0
        
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
