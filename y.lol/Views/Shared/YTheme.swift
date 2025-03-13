//
//  YTheme.swift
//  y.lol
//
//  Created by Andrea Russo on 3/13/25.
//

import SwiftUI

/// The main theme namespace for y.lol
enum YTheme {
    /// Core color palette for the app
    enum Colors {
        // Base colors
        static let parchmentLight = Color(hex: "F5F2E9")
        static let parchmentDark = Color(hex: "1C1C1E")
        static let textLight = Color(hex: "2C2C2C")
        static let textDark = Color(hex: "F5F2E9")
        static let accentLight = Color(hex: "E4D5B7")
        static let accentDark = Color(hex: "B8A179")
        
        /// Dynamic colors that automatically adapt to color scheme
        struct Dynamic {
            @Environment(\.colorScheme) private var colorScheme
            
            var background: Color {
                colorScheme == .light ? parchmentLight : parchmentDark
            }
            
            var text: Color {
                colorScheme == .light ? textLight : textDark
            }
            
            var accent: Color {
                colorScheme == .light ? accentLight : accentDark
            }
            
            /// Returns text color with custom opacity
            func text(opacity: Double) -> Color {
                text.opacity(opacity)
            }
            
            /// Returns background color with noise overlay
            var backgroundWithNoise: some View {
                background.overlay(
                    Color.primary
                        .opacity(0.03)
                        .blendMode(.multiply)
                )
            }
        }
        
        /// Access dynamic colors
        static var dynamic: Dynamic {
            Dynamic()
        }
    }
    
    /// Typography definitions
    enum Typography {
        static func serif(size: CGFloat, weight: Font.Weight = .regular) -> Font {
            .system(size: size, weight: weight, design: .serif)
        }
        
        static func regular(size: CGFloat, weight: Font.Weight = .regular) -> Font {
            .system(size: size, weight: weight)
        }
    }
}

// Keep the Color hex extension here since it's theme-related
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    Group {
        VStack(spacing: 20) {
            // Header to show which theme we're looking at
            Text("Theme Preview")
                .font(YTheme.Typography.serif(size: 24, weight: .bold))
            
            // Color samples
            VStack(alignment: .leading, spacing: 16) {
                ColorSampleRow(label: "Background", color: YTheme.Colors.dynamic.background)
                ColorSampleRow(label: "Text", color: YTheme.Colors.dynamic.text)
                ColorSampleRow(label: "Accent", color: YTheme.Colors.dynamic.accent)
            }
            .padding()
            .background(YTheme.Colors.dynamic.backgroundWithNoise)
            .cornerRadius(12)
            
            // Mock message bubbles to simulate ContentView
            VStack(spacing: 12) {
                MessageBubble(text: "Hello there!", isUser: false)
                MessageBubble(text: "Hi! How are you?", isUser: true)
            }
            .padding()
        }
        .padding()
        .background(YTheme.Colors.dynamic.background)
    }
}

// Helper views for the preview
private struct ColorSampleRow: View {
    let label: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(YTheme.Colors.dynamic.text)
            Spacer()
            RoundedRectangle(cornerRadius: 6)
                .fill(color)
                .frame(width: 60, height: 30)
        }
    }
}

private struct MessageBubble: View {
    let text: String
    let isUser: Bool
    
    var body: some View {
        HStack {
            if isUser { Spacer() }
            Text(text)
                .padding(12)
                .background(isUser ? YTheme.Colors.dynamic.accent : YTheme.Colors.dynamic.text.opacity(0.1))
                .foregroundColor(isUser ? YTheme.Colors.dynamic.text : YTheme.Colors.dynamic.text)
                .cornerRadius(16)
            if !isUser { Spacer() }
        }
    }
}
