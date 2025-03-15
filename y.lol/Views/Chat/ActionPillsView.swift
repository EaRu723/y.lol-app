import SwiftUI

struct ActionPillsView: View {
    var onPillTapped: (Int) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { index in
                    Button(action: {
                        onPillTapped(index)
                    }) {
                        Text(getPillText(for: index))
                            .font(.subheadline)
                            .lineLimit(1)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.gray.opacity(0.1)))
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func getPillText(for index: Int) -> String {
        switch index {
        case 0: return "Vibe Check 🤑"
        case 1: return "Vent Mode 😡"
        case 2: return "Existential Crisis 🫠"
        case 3: return "Roast Me 🌶️"
        default: return ""
        }
    }
} 
