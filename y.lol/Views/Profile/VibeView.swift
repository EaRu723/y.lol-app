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
    var isLoading: Bool = false
    
    @Environment(\.themeColors) private var colors
    
    var body: some View {
        VStack(spacing: YTheme.Spacing.small) {
            Text("My Vibe")
                .font(YTheme.Typography.title)
                .foregroundColor(colors.text)
            
            ZStack {
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
                
                if isLoading {
                    ProgressView()
                }
            }
            
            if onShuffle != nil {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        onShuffle?()
                    }) {
                        Image(systemName: "shuffle")
                            .foregroundColor(colors.text)
                            .padding(.trailing, YTheme.Spacing.medium)
                    }
                }
            }
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
