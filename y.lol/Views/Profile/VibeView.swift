//
//  VibeView.swift
//  y.lol
//
//  Created by Andrea Russo on 3/24/25.
//

import SwiftUI

struct VibeView: View {
    let vibe: String
    var fontSize: CGFloat = 16
    var padding: CGFloat = 10
    
    @Environment(\.themeColors) private var colors
    
    var body: some View {
        Text(vibe.isEmpty ? "No vibe set" : vibe)
            .font(.system(size: fontSize, weight: .medium, design: .serif))
            .foregroundColor(colors.text)
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(colors.accent.opacity(0.01))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.black, lineWidth: 1)
            )
    }
}

#Preview {
    VStack(spacing: 20) {
        VibeView(vibe: "Peaceful")
        VibeView(vibe: "Energetic")
        VibeView(vibe: "")
    }
    .padding()
    .withYTheme()
}
