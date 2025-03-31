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
            HStack {
                Text(suggestionText)
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .foregroundColor(YTheme.Colors.textLight)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(16)
            }
            .frame(alignment: .leading)
        }
        .buttonStyle(.plain)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
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
