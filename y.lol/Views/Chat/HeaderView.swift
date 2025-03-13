//
//  HeaderView.swift
//  y.lol
//
//  Created by Andrea Russo on 3/11/25.
//

import SwiftUI

struct HeaderView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isThinking: Bool
    @Binding var showProfile: Bool  // New binding for profile sheet
    @State private var showButtons = false // Added missing state variable
    
    // Colors based on color scheme
    private var colors: (background: Color, text: Color, accent: Color) {
        switch colorScheme {
        case .light:
            return (
                background: Color(hex: "F5F2E9"),    // light parchment
                text: Color(hex: "2C2C2C"),          // dark gray
                accent: Color(hex: "E4D5B7")         // warm beige
            )
        case .dark:
            return (
                background: Color(hex: "1C1C1E"),    // dark background
                text: Color(hex: "F5F2E9"),          // light text
                accent: Color(hex: "B8A179")         // darker warm accent
            )
        @unknown default:
            return (
                background: Color(hex: "F5F2E9"),
                text: Color(hex: "2C2C2C"),
                accent: Color(hex: "E4D5B7")
            )
        }
    }
    
    var body: some View {
        HStack {
            Button(action: {
                // Menu action
            }) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20))
                    .foregroundColor(colorScheme == .light ?
                        Color(hex: "2C2C2C").opacity(0.8) :
                        Color(hex: "F5F2E9").opacity(0.8))
            }
            .opacity(showButtons ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: showButtons)
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    showButtons.toggle()
                }
            }) {
                // YinYang logo with colors matching the theme
                YinYangLogoView(
                    size: 40,
                    isLoading: isThinking,
                    lightColor: colorScheme == .light ? .white : Color(hex: "1C1C1E"),
                    darkColor: colorScheme == .light ? Color(hex: "2C2C2C") : Color(hex: "F5F2E9")
                )
                .background(
                    Circle()
                        .fill(Color.clear)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
                .rotationEffect(Angle(degrees: 90))
            }
            
            Spacer()
            
            Button(action: {
                // Profile action - show profile sheet
                showProfile = true
            }) {
                Image(systemName: "person.circle")
                    .font(.system(size: 20))
                    .foregroundColor(colorScheme == .light ?
                        Color(hex: "2C2C2C").opacity(0.8) :
                        Color(hex: "F5F2E9").opacity(0.8))
            }
            .opacity(showButtons ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: showButtons)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
}

struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Light mode preview
            HeaderView(isThinking: .constant(false), showProfile: .constant(false))
                .previewLayout(.sizeThatFits)
                .padding()
                .background(Color(hex: "F5F2E9"))
                .previewDisplayName("Light Mode")
            
            // Dark mode preview
            HeaderView(isThinking: .constant(true), showProfile: .constant(false))
                .previewLayout(.sizeThatFits)
                .padding()
                .background(Color(hex: "1C1C1E"))
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode (Loading)")
        }
    }
}
