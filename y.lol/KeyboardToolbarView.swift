//
//  KeyboardToolbarView.swift
//  y.lol
//
//  Created by Andrea Russo on 3/1/25.
//

import SwiftUI

struct KeyboardToolbarView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var text: String
    let onSend: () -> Void
    let hapticService: HapticService
    
    private let quickEmojis = ["🤔", "🥵", "🤬"]
    
    private var isMessageEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        HStack {
            Button(action: {
                // Photo picker action
            }) {
                Image(systemName: "photo")
                    .font(.system(size: 20))
                    .foregroundColor(colors.text.opacity(0.8))
            }
            
            Spacer()
            
            ForEach(quickEmojis, id: \.self) { emoji in
                Button(action: {
                    text += emoji
                }) {
                    Text(emoji)
                        .font(.system(size: 20))
                }
            }
            
            Spacer()
            
            Button(action: {
                guard !isMessageEmpty else { return }
                onSend()
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(isMessageEmpty ?
                        colors.text.opacity(0.4) :
                        colors.text.opacity(0.8))
            }
            .disabled(isMessageEmpty)
        }
    }
    
    private var colors: (background: Color, text: Color, accent: Color) {
        switch colorScheme {
        case .light:
            return (
                background: Color(hex: "F5F2E9"),
                text: Color(hex: "2C2C2C"),
                accent: Color(hex: "E4D5B7")
            )
        case .dark:
            return (
                background: Color(hex: "1C1C1E"),
                text: Color(hex: "F5F2E9"),
                accent: Color(hex: "B8A179")
            )
        @unknown default:
            return (
                background: Color(hex: "F5F2E9"),
                text: Color(hex: "2C2C2C"),
                accent: Color(hex: "E4D5B7")
            )
        }
    }
}

