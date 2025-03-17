import SwiftUI

struct ActionPillsView: View {
    var currentMode: FirebaseManager.ChatMode
    var onPillTapped: (FirebaseManager.ChatMode) -> Void

    // Track selected mode pill
    @State private var selectedPillIndex: Int = 0
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { index in
                    let mode = getPillMode(for: index)
                    Button(action: {
                        onPillTapped(mode)
                    }) {
                        Text(getPillText(for: index))
                            .font(.subheadline)
                            .lineLimit(1)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(currentMode == mode ? Color.gray.opacity(0.4) : Color.gray.opacity(0.1)))
                            .foregroundColor(
                                currentMode == mode ? Color.primary : Color.primary.opacity(0.7)
                            )
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func getPillText(for index: Int) -> String {
        switch index {
        case 0: return "Y ☯️"
        case 1: return "Vibe Check 🤑"
        case 2: return "Vent Mode 😡"
        case 3: return "Existential Crisis 🫠"
        case 4: return "Roast Me 🌶️"
        default: return ""
        }
    }
    
    private func getPillMode(for index: Int) -> FirebaseManager.ChatMode {
        switch index {
        case 0: return .reg
        case 1: return .vibeCheck
        case 2: return .ventMode
        case 3: return .existentialCrisis
        case 4: return .roastMe
        default: return .reg
        }
    }
}
