import SwiftUI

// Add these types
enum Sender {
    case yin, yang
}

struct OnboardingMessage: Identifiable {
    let id = UUID()
    let sender: Sender
    let text: String
}

struct OnboardingPage {

    
    // Add messages array
    let messages: [OnboardingMessage]
    let buttonText: String
    let hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle
    
    // Update initializers if needed, or remove old ones if no longer used.
    // This example assumes a new primary initializer.
    init(messages: [OnboardingMessage], buttonText: String, hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle) {
        self.messages = messages
        self.buttonText = buttonText
        self.hapticStyle = hapticStyle
    }
} 