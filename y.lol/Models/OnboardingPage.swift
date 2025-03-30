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
    // Remove old text properties
    // let yinText: String
    // let yangText: String
    
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

    // Keep or remove this initializer based on whether you still need backward compatibility
    // init(text: String, buttonText: String, hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle) {
    //     self.messages = [OnboardingMessage(sender: .yin, text: text)] // Example adaptation
    //     self.buttonText = buttonText
    //     self.hapticStyle = hapticStyle
    // }
} 