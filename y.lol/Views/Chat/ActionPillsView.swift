import SwiftUI

struct ActionPillsView: View {
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
}
