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
    @Binding var showProfile: Bool
    @State private var showButtons = false
    
    var body: some View {
        HStack {
            Button(action: {
                // Menu action
            }) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
            .opacity(showButtons ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: showButtons)
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    showButtons.toggle()
                }
            }) {
                YinYangLogoView(
                    size: 40,
                    isLoading: isThinking,
                    lightColor: colorScheme == .light ? .white : YTheme.Colors.parchmentDark,
                    darkColor: colorScheme == .light ? YTheme.Colors.textLight : YTheme.Colors.textDark
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
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
            .opacity(showButtons ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: showButtons)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(colorScheme == .dark ? Color.black : Color.white)
    }
}

struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Light mode preview
            HeaderView(isThinking: .constant(false), showProfile: .constant(false))
                .previewLayout(.sizeThatFits)
                .padding()
                .background(Color.white)
                .previewDisplayName("Light Mode")
            
            // Dark mode preview
            HeaderView(isThinking: .constant(true), showProfile: .constant(false))
                .previewLayout(.sizeThatFits)
                .padding()
                .background(Color.black)
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode (Loading)")
        }
    }
}
