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
    var onShuffle: (() -> Void)?
    
    @Environment(\.themeColors) private var colors
    
    var body: some View {
        VStack(spacing: YTheme.Spacing.small) {
            HStack {
                Text("Vibe")
                    .font(YTheme.Typography.title)
                    .foregroundColor(colors.text)
                
                if onShuffle != nil {
                    Spacer()
                    
                    Button(action: {
                        onShuffle?()
                    }) {
                        Image(systemName: "shuffle")
                            .foregroundColor(colors.text)
                    }
                }
            }
            
            Text(vibe.isEmpty ? "No vibe set" : vibe)
                .font(YTheme.Typography.body)
                .foregroundColor(colors.text)
                .padding(YTheme.Spacing.medium)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(colors.accent.opacity(0.01))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(colors.text, lineWidth: 1)
                )
        }
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
