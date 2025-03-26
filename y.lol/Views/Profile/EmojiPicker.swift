//
//  EmojiPicker.swift
//  y.lol
//
//  Created by Andrea Russo on 3/26/25.
//

import SwiftUI

struct EmojiPicker: View {
    @Binding var selectedEmoji: String
    @Environment(\.themeColors) private var colors
    
    let emojis = ["😊", "😎", "🤓", "🥳", "😇", "🤠", "🦄", "🌟", "🌈", "✨", "🎯", "🎨", "🎭", "🎪", "☯️"]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Choose your emoji")
                .font(YTheme.Typography.caption)
                .foregroundColor(colors.text(opacity: 0.7))
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                ForEach(emojis, id: \.self) { emoji in
                    Button(action: {
                        selectedEmoji = emoji
                    }) {
                        Text(emoji)
                            .font(.system(size: 30))
                            .padding(8)
                            .background(selectedEmoji == emoji ? colors.accent.opacity(0.3) : Color.clear)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}
