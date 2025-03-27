import SwiftUI

struct ChatModeButtons: View {
    @Environment(\.themeColors) private var colors
    var currentMode: FirebaseManager.ChatMode
    var onPillTapped: (FirebaseManager.ChatMode) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(0..<2, id: \.self) { index in
                    let mode = getPillMode(for: index)
                    Button(action: {
                        onPillTapped(mode)
                    }) {
                        Text(getPillText(for: index))
                            .font(.headline)
                            .lineLimit(1)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(currentMode == mode ? colors.accent.opacity(0.4) : colors.accent.opacity(0)))
                            .foregroundColor(
                                currentMode == mode ? colors.text : colors.text(opacity: 0.9)
                            )
                            .shadow(color: getShadowColor(for: mode, isSelected: currentMode == mode), 
                                   radius: currentMode == mode ? 4 : 0)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func getPillText(for index: Int) -> String {
        switch index {
        case 0: return "😇"
        case 1: return "😈"
        default: return ""
        }
    }
    
    private func getPillMode(for index: Int) -> FirebaseManager.ChatMode {
        switch index {
        case 0: return .yin
        case 1: return .yang
        default: return .yin
        }
    }
    
    private func getShadowColor(for mode: FirebaseManager.ChatMode, isSelected: Bool) -> Color {
        guard isSelected else { return .clear }
        switch mode {
        case .yin: return Color.blue.opacity(0.5)
        case .yang: return Color.red.opacity(0.5)
        }
    }
}

#Preview("ActionPillsView") {
    VStack(spacing: 20) {
        // Preview Yin mode
        ChatModeButtons(
            currentMode: .yin,
            onPillTapped: { mode in
                print("Tapped mode: \(mode)")
            }
        )
        .padding()
        .background(Color.white)
        
        // Preview Yang mode
        ChatModeButtons(
            currentMode: .yang,
            onPillTapped: { mode in
                print("Tapped mode: \(mode)")
            }
        )
        .padding()
        .background(Color.black)
    }
    .withYTheme() // Assuming this modifier exists for theming
}
