import SwiftUI

struct OnboardingYinYangTextView: View {
    let yinText: String
    let yangText: String
    let textSize: CGFloat
    let spacing: CGFloat
    
    init(yinText: String, yangText: String, textSize: CGFloat = 18, spacing: CGFloat = 16) {
        self.yinText = yinText
        self.yangText = yangText
        self.textSize = textSize
        self.spacing = spacing
    }
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.themeColors) private var colors
    
    var body: some View {
        VStack(spacing: spacing) {
            // Yin (Angel) line
            HStack(spacing: 10) {
                Text("😇")
                    .font(.system(size: textSize * 1.2))
                
                Text(yinText)
                    .font(YTheme.Typography.serif(size: textSize, weight: .light))
                    .foregroundColor(colors.text)
            }
            
            // Yang (Devil) line
            HStack(spacing: 10) {
                Text("😈")
                    .font(.system(size: textSize * 1.2))
                
                Text(yangText)
                    .font(YTheme.Typography.serif(size: textSize, weight: .light))
                    .foregroundColor(colors.text)
            }
        }
        .padding(.horizontal)
        .multilineTextAlignment(.leading)
    }
}

#Preview {
    VStack {
        OnboardingYinYangTextView(
            yinText: "Be kind to others",
            yangText: "But don't let them take advantage of you"
        )
        
        Divider().padding()
        
        OnboardingYinYangTextView(
            yinText: "Work hard",
            yangText: "Play harder",
            textSize: 22,
            spacing: 24
        )
    }
    .padding()
    .background(Color(.systemBackground))
} 
