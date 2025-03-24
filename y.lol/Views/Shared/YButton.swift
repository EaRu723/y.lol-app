//
//  YButton.swift
//  y.lol
//
//  Created on 3/25/25.
//

import SwiftUI

struct YButton: View {
    @Environment(\.themeColors) private var colors
    
    var title: String
    var isLoading: Bool = false
    var isPrimary: Bool = true
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(isPrimary ? Color.white : colors.text)
                } else {
                    Text(title)
                        .font(YTheme.Typography.body)
                }
            }
            .foregroundColor(isPrimary ? Color.white : colors.text)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isPrimary ? colors.accent : colors.accent.opacity(0.3))
            .cornerRadius(10)
        }
        .disabled(isLoading)
    }
} 