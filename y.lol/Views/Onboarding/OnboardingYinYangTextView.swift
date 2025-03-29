import SwiftUI

struct OnboardingYinYangTextView: View {
    let yinText: String
    let yangText: String
    let textSize: CGFloat
    let spacing: CGFloat
    let emojiSize: CGFloat
    let emojiColumnWidth: CGFloat
    
    init(
        yinText: String, 
        yangText: String, 
        textSize: CGFloat = 18, 
        spacing: CGFloat = 16,
        emojiSize: CGFloat = 44,
        emojiColumnWidth: CGFloat = 50
    ) {
        self.yinText = yinText
        self.yangText = yangText
        self.textSize = textSize
        self.spacing = spacing
        self.emojiSize = emojiSize
        self.emojiColumnWidth = emojiColumnWidth
    }
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.themeColors) private var colors
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            // Yin (Angel) row
            HStack(alignment: .top, spacing: 0) {
                // Fixed-width emoji column
                VStack {
                    Text("😇")
                        .font(.system(size: emojiSize))
                }
                .frame(width: emojiColumnWidth, alignment: .center)
                
                // Text column that takes remaining space
                Text(yinText)
                    .font(YTheme.Typography.serif(size: textSize, weight: .light))
                    .foregroundColor(colors.text)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Yang (Devil) row
            HStack(alignment: .top, spacing: 0) {
                // Fixed-width emoji column
                VStack {
                    Text("😈")
                        .font(.system(size: emojiSize))
                }
                .frame(width: emojiColumnWidth, alignment: .center)
                
                // Text column that takes remaining space
                Text(yangText)
                    .font(YTheme.Typography.serif(size: textSize, weight: .light))
                    .foregroundColor(colors.text)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 30) {
        Text("Default Configuration")
            .font(.headline)
        
        OnboardingYinYangTextView(
            yinText: "Be kind to others and remember that kindness is a virtue that ripples outward",
            yangText: "But don't let them take advantage of your good nature"
        )
        
        Divider()
        
        Text("Custom Sizing")
            .font(.headline)
        
        OnboardingYinYangTextView(
            yinText: "Work hard and persist through difficulties",
            yangText: "Play harder and enjoy the fruits of your labor",
            textSize: 22,
            spacing: 24,
            emojiSize: 64,
            emojiColumnWidth: 60
        )
        
        Divider()
        
        Text("During Animation (Empty Text)")
            .font(.headline)
        
        OnboardingYinYangTextView(
            yinText: "",
            yangText: "",
            textSize: 18,
            spacing: 16,
            emojiSize: 64
        )
        
        Divider()
        
        Text("Partial Animation")
            .font(.headline)
        
        OnboardingYinYangTextView(
            yinText: "This text is complete",
            yangText: "",
            textSize: 18,
            spacing: 16,
            emojiSize: 64
        )
    }
    .padding()
    .frame(maxWidth: .infinity)
    .background(Color(.systemBackground))
} 
