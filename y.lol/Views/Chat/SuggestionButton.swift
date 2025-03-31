//
//  SuggestionButton.swift
//  y.lol
//
//  Created on 3/15/25.
//

import SwiftUI

struct SuggestionButton: View {

    let mode: FirebaseManager.ChatMode
    let action: (String) -> Void
    
    // Array of suggestions for each mode
    private var suggestions: [String] {
        switch mode {
        case .yin:
            return ["Praise me 🥹", "Vibe check 🧘‍♀️", "Calm me 😌"]
        case .yang:
            return ["Roast me 🥵", "Gas me up 🔥", "Rate my fit 👕"]
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(suggestions, id: \.self) { suggestion in
                Button(action: { action(suggestion) }) {
                    Text(suggestion)
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .foregroundColor(YTheme.Colors.textLight)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(16)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(alignment: .leading)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}

struct SuggestionButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SuggestionButton(mode: .yin) { suggestion in
                print("Yin suggestion tapped: \(suggestion)")
            }
            SuggestionButton(mode: .yang) { suggestion in
                print("Yang suggestion tapped: \(suggestion)")
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .withYTheme() // Apply theme for preview
    }
} 
