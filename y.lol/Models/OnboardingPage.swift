import SwiftUI

struct OnboardingPage {
    let yinText: String
    let yangText: String
    let buttonText: String
    let hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle
    
    // For backward compatibility with pages that use single text
    init(text: String, buttonText: String, hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle) {
        self.yinText = text
        self.yangText = ""
        self.buttonText = buttonText
        self.hapticStyle = hapticStyle
    }
    
    // New initializer for yin-yang paired text
    init(yinText: String, yangText: String, buttonText: String, hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle) {
        self.yinText = yinText
        self.yangText = yangText
        self.buttonText = buttonText
        self.hapticStyle = hapticStyle
    }
} 