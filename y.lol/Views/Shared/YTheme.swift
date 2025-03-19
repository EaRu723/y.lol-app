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
        
        // Message bubble colors
        static let userBubbleLight = Color(hex: "E4D5B7")  // Same as accentLight
        static let userBubbleDark = Color(hex: "B8A179")   // Same as accentDark
        static let aiMessageBubbleLight = Color(hex: "E4E2DA")
        static let aiMessageBubbleDark = Color(hex: "2C2C2E")
        
        /// Dynamic colors that automatically adapt to color scheme
        struct Dynamic {
            let colorScheme: ColorScheme
            
            init(colorScheme: ColorScheme) {
                self.colorScheme = colorScheme
            }
            
            var background: Color {
                colorScheme == .light ? parchmentLight : parchmentDark
            }
            
            var text: Color {
                colorScheme == .light ? textLight : textDark
            }
            
            var accent: Color {
                colorScheme == .light ? accentLight : accentDark
            }
            
            // New properties for message bubbles
            var userMessageBubble: Color {
                colorScheme == .light ? userBubbleLight : userBubbleDark
            }
            
            var aiMessageBubble: Color {
                colorScheme == .light ? aiMessageBubbleLight : aiMessageBubbleDark
            }
            
            var userMessageText: Color {
                colorScheme == .light ? textLight : textDark
            }
            
            var aiMessageText: Color {
                colorScheme == .light ? textLight : textDark
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
    }
    
    /// Typography definitions
    enum Typography {
        static func serif(size: CGFloat, weight: Font.Weight = .regular) -> Font {
            .custom("Baskerville", size: size)
        }
        
        static func regular(size: CGFloat, weight: Font.Weight = .regular) -> Font {
            .system(size: size, weight: weight)
        }
        
        // Add these new convenience methods
        static var title: Font {
            serif(size: 24, weight: .bold)
        }
        
        static var subtitle: Font {
            serif(size: 18, weight: .medium)
        }
        
        static var body: Font {
            serif(size: 16, weight: .regular)
        }
        
        static var caption: Font {
            regular(size: 12, weight: .light)
        }
        
        static var small: Font {
            regular(size: 10, weight: .medium)
        }
    }
}

// MARK: - Environment Integration

/// Define a custom environment key for YTheme colors
private struct ThemeColorsKey: EnvironmentKey {
    static let defaultValue: YTheme.Colors.Dynamic = YTheme.Colors.Dynamic(colorScheme: .light)
}

/// Extend environment values to include theme colors
extension EnvironmentValues {
    var themeColors: YTheme.Colors.Dynamic {
        get { self[ThemeColorsKey.self] }
        set { self[ThemeColorsKey.self] = newValue }
    }
}

/// View modifier to automatically update theme colors based on colorScheme
struct ThemeModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .environment(\.themeColors, YTheme.Colors.Dynamic(colorScheme: colorScheme))
    }
}

/// View extension to easily apply the theme
extension View {
    func withYTheme() -> some View {
        modifier(ThemeModifier())
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


struct MessageBubble: View {
    @Environment(\.themeColors) private var colors
    let text: String
    let isUser: Bool
    
    var body: some View {
        HStack {
            if isUser { Spacer() }
            Text(text)
                .padding(12)
                .background(isUser ? colors.userMessageBubble : colors.aiMessageBubble)
                .foregroundColor(isUser ? colors.userMessageText : colors.aiMessageText)
                .cornerRadius(16)
            if !isUser { Spacer() }
        }
    }
}
