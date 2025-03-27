import SwiftUI

struct ChatHeaderButtons: View {
    @Environment(\.themeColors) private var colors
    @Environment(\.colorScheme) private var colorScheme
    var currentMode: FirebaseManager.ChatMode
    var onPillTapped: (FirebaseManager.ChatMode) -> Void
    var showButtons: Bool
    var isThinking: Bool
    var onCenterTapped: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Yin button
            Button(action: {
                onPillTapped(.yin)
            }) {
                Text("😇")
                    .font(.headline)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(currentMode == .yin ? colors.accent.opacity(0.4) : colors.accent.opacity(0)))
                    .foregroundColor(currentMode == .yin ? colors.text : colors.text(opacity: 0.9))
                    .shadow(color: getShadowColor(for: .yin, isSelected: currentMode == .yin), 
                           radius: currentMode == .yin ? 4 : 0)
            }
            .opacity(showButtons ? 1 : 0)
            
            // Center YinYang button
            Button(action: onCenterTapped) {
                if isThinking {
                    YinYangLogoView(
                        size: 40,
                        isLoading: true,
                        lightColor: colorScheme == .light ? .white : YTheme.Colors.parchmentDark,
                        darkColor: colorScheme == .light ? YTheme.Colors.textLight : YTheme.Colors.textDark
                    )
                    .background(Circle().fill(Color.clear))
                    .rotationEffect(Angle(degrees: 90))
                    .shadow(color: getShadowColor(for: currentMode, isSelected: true), radius: 3, x: 0, y: 1)
                } else {
                    YinYangLogoView(
                        size: 40,
                        isLoading: false,
                        lightColor: colorScheme == .light ? .white : YTheme.Colors.parchmentDark,
                        darkColor: colorScheme == .light ? YTheme.Colors.textLight : YTheme.Colors.textDark
                    )
                    .background(Circle().fill(Color.clear))
                    .rotationEffect(Angle(degrees: 90))
                    .shadow(color: getShadowColor(for: currentMode, isSelected: true), radius: 3, x: 0, y: 1)
                }
            }
            .padding(.horizontal, 24)
            
            // Yang button
            Button(action: {
                onPillTapped(.yang)
            }) {
                Text("😈")
                    .font(.headline)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(currentMode == .yang ? colors.accent.opacity(0.4) : colors.accent.opacity(0)))
                    .foregroundColor(currentMode == .yang ? colors.text : colors.text(opacity: 0.9))
                    .shadow(color: getShadowColor(for: .yang, isSelected: currentMode == .yang), 
                           radius: currentMode == .yang ? 4 : 0)
            }
            .opacity(showButtons ? 1 : 0)
        }
        .padding(.horizontal)
    }
    
    private func getShadowColor(for mode: FirebaseManager.ChatMode, isSelected: Bool) -> Color {
        guard isSelected else { return .clear }
        switch mode {
        case .yin: return Color.blue.opacity(0.3)
        case .yang: return Color.red.opacity(0.3)
        }
    }
}

#Preview("ActionPillsView") {
    VStack(spacing: 20) {
        // Preview Yin mode
        ChatHeaderButtons(
            currentMode: .yin,
            onPillTapped: { mode in
                print("Tapped mode: \(mode)")
            },
            showButtons: true,
            isThinking: false,
            onCenterTapped: {}
        )
        .padding()
        .background(Color.white)
        
        // Preview Yang mode
        ChatHeaderButtons(
            currentMode: .yang,
            onPillTapped: { mode in
                print("Tapped mode: \(mode)")
            },
            showButtons: true,
            isThinking: false,
            onCenterTapped: {}
        )
        .padding()
        .background(Color.black)
    }
    .withYTheme() // Assuming this modifier exists for theming
}
