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
        // Base colors - Make these pure black and white
        static let parchmentLight = Color.white
        static let parchmentDark = Color.black
        static let textLight = Color.black
        static let textDark = Color.white
        
        // Change accent colors to grayscale
        static let accentLight = Color(white: 0.9) // Light gray
        static let accentDark = Color(white: 0.2)  // Dark gray
        
        // Message bubble colors - already black and white
        static let userBubbleLight = Color.black
        static let userBubbleDark = Color.white
        static let aiMessageBubbleLight = Color.white
        static let aiMessageBubbleDark = Color.black
        
        // Add Yin (blue) and Yang (red) shadow colors
        static let yinShadowLight = Color(hex: "3B82F6") // Blue 500
        static let yinShadowDark = Color(hex: "60A5FA") // Blue 400
        static let yangShadowLight = Color(hex: "EF4444") // Red 500
        static let yangShadowDark = Color(hex: "F87171") // Red 400
        
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
            
            // Yin and Yang shadow colors
            var yinShadow: Color {
                colorScheme == .light ? yinShadowLight : yinShadowDark
            }
            
            var yangShadow: Color {
                colorScheme == .light ? yangShadowLight : yangShadowDark
            }
            
            // New properties for message bubbles
            var userMessageBubble: Color {
                colorScheme == .light ? userBubbleLight : userBubbleDark
            }
            
            var aiMessageBubble: Color {
                colorScheme == .light ? aiMessageBubbleLight : aiMessageBubbleDark
            }
            
            // Updated message bubble text colors to ensure contrast
            var userMessageText: Color {
                colorScheme == .light ? .white : .black // Reversed text color for contrast
            }
            
            var aiMessageText: Color {
                colorScheme == .light ? .black : .white // Same as background text
            }
            
            /// Returns text color with custom opacity
            func text(opacity: Double) -> Color {
                text.opacity(opacity)
            }
            
            /// Returns background color without noise
            var backgroundWithNoise: some View {
                // Removed noise overlay, now just returns the plain background color
                background
            }
        }
    }
    
    /// Standardized spacing system for consistent layouts
    enum Spacing {
        // Edge spacing
        static let screenEdge: CGFloat = 16
        static let safeArea: CGFloat = 20
        
        // Content spacing
        static let tiny: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xlarge: CGFloat = 32
        static let xxlarge: CGFloat = 48
        
        // Component-specific spacing
        static let buttonPadding: CGFloat = 12
        static let cardPadding: CGFloat = 16
        static let inputFieldHeight: CGFloat = 44
        
        // Stack spacing
        static let vStackDefault: CGFloat = 12
        static let hStackDefault: CGFloat = 10
        
        // List and grid spacing
        static let listRowSpacing: CGFloat = 8
        static let gridSpacing: CGFloat = 12
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

// MARK: - Common Layout Modifiers

/// Adds standard screen edge padding
extension View {
    func withScreenEdgePadding() -> some View {
        self.padding(.horizontal, YTheme.Spacing.screenEdge)
    }
    
    func withStandardSpacing() -> some View {
        self.padding(YTheme.Spacing.medium)
    }
    
    // For Yin mode elements with blue shadow
    func withYinShadow(radius: CGFloat = 4) -> some View {
        self.modifier(YinShadowModifier(radius: radius))
    }
    
    // For Yang mode elements with red shadow
    func withYangShadow(radius: CGFloat = 4) -> some View {
        self.modifier(YangShadowModifier(radius: radius))
    }
}

// Shadow modifiers for Yin and Yang elements
struct YinShadowModifier: ViewModifier {
    @Environment(\.themeColors) private var colors
    let radius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .shadow(color: colors.yinShadow.opacity(0.5), radius: radius, x: 0, y: 2)
    }
}

struct YangShadowModifier: ViewModifier {
    @Environment(\.themeColors) private var colors
    let radius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .shadow(color: colors.yangShadow.opacity(0.5), radius: radius, x: 0, y: 2)
    }
}

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
                .font(.system(size: 15))
                .padding(YTheme.Spacing.buttonPadding)
                .background(isUser ? colors.userMessageBubble : colors.aiMessageBubble)
                .foregroundColor(isUser ? colors.userMessageText : colors.aiMessageText)
                .cornerRadius(16)
            if !isUser { Spacer() }
        }
    }
}
