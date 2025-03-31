//
//  SuggestionButton.swift
//  y.lol
//
//  Created on 3/15/25.
//

import SwiftUI

struct SuggestionButton: View {

    let mode: FirebaseManager.ChatMode
    let action: () -> Void

    private var suggestionText: String {
        switch mode {
        case .yin:
            return "Compliment me 🥹"
        case .yang:
            return "Roast me 🥵"
        }
    }

    var body: some View {
        Button(action: action) {
            Text(suggestionText)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .foregroundColor(YTheme.Colors.textLight) // Use static black text color
                .background(YTheme.Colors.parchmentLight) // Use static white background
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(YTheme.Colors.textLight, lineWidth: 1) // Use static black border color
                )
        }
        .buttonStyle(.plain) // Use plain style to avoid default button chrome
        .transition(.opacity.combined(with: .move(edge: .bottom))) // Add transition
    }
}


struct SuggestionButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SuggestionButton(mode: .yin) {
                print("Yin suggestion tapped")
            }
            SuggestionButton(mode: .yang) {
                print("Yang suggestion tapped")
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .withYTheme() // Apply theme for preview
    }
} 
