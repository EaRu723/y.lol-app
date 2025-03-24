//
//  HeaderView.swift
//  y.lol
//
//  Created by Andrea Russo on 3/11/25.
//

import SwiftUI

struct HeaderView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.themeColors) private var colors
    @Binding var isThinking: Bool
    @Binding var showProfile: Bool
    @State private var showButtons = false
    @Binding var isSearching: Bool
    var currentMode: FirebaseManager.ChatMode
    var onPillTapped: (FirebaseManager.ChatMode) -> Void
    var onSaveChat: () -> Void
    
    var body: some View {
        HStack {
            Button(action: {
                withAnimation {
                    isSearching.toggle()
                }
            }) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
            }
            .opacity(showButtons ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: showButtons)
            
            Spacer()
            
            // Yin (😇) pill button
            Button(action: {
                onPillTapped(.yin)
                onSaveChat()
            }) {
                Text("😇")
                    .font(.system(size: 20))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(currentMode == .yin ? Color.gray.opacity(0.2) : Color.clear))
                    .foregroundColor(currentMode == .yin ? Color.primary : Color.primary.opacity(0.7))
            }
            .opacity(showButtons ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: showButtons)
            
            Spacer(minLength: 8)
            
            Button(action: {
                withAnimation {
                    showButtons.toggle()
                }
            }) {
                if isThinking {
                    YinYangLogoView(
                        size: 40,
                        isLoading: true,
                        lightColor: colorScheme == .light ? .white : YTheme.Colors.parchmentDark,
                        darkColor: colorScheme == .light ? YTheme.Colors.textLight : YTheme.Colors.textDark
                    )
                    .background(
                        Circle()
                            .fill(Color.clear)
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )
                    .rotationEffect(Angle(degrees: 90))
                } else if showButtons {
                    YinYangLogoView(
                        size: 40,
                        isLoading: false,
                        lightColor: colorScheme == .light ? .white : YTheme.Colors.parchmentDark,
                        darkColor: colorScheme == .light ? YTheme.Colors.textLight : YTheme.Colors.textDark
                    )
                    .background(
                        Circle()
                            .fill(Color.clear)
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )
                    .rotationEffect(Angle(degrees: 90))
                } else {
                    Text(currentMode == .yin ? "😇" : "😈")
                        .font(.system(size: 25))
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color.gray.opacity(0.1))
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        )
                }
            }
            
            Spacer(minLength: 8)
            
            // Yang (😈) pill button
            Button(action: {
                onPillTapped(.yang)
                onSaveChat()
            }) {
                Text("😈")
                    .font(.system(size: 20))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(currentMode == .yang ? Color.gray.opacity(0.2) : Color.clear))
                    .foregroundColor(currentMode == .yang ? Color.primary : Color.primary.opacity(0.7))
            }
            .opacity(showButtons ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: showButtons)
            
            Spacer()
            
            Button(action: {
                // Profile action - show profile sheet
                showProfile = true
            }) {
                Image(systemName: "person.circle")
                    .font(.system(size: 20))
                    .foregroundColor(colors.text)
            }
            .opacity(showButtons ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: showButtons)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(colors.background)
    }
}

struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Light mode preview
            HeaderView(
                isThinking: .constant(false), 
                showProfile: .constant(false),
                isSearching: .constant(false),
                currentMode: .yin,
                onPillTapped: { _ in },
                onSaveChat: {}
            )
                .previewLayout(.sizeThatFits)
                .padding()
                .background(Color.white)
                .previewDisplayName("Light Mode")
            
            // Dark mode preview
            HeaderView(
                isThinking: .constant(true), 
                showProfile: .constant(false),
                isSearching: .constant(false),
                currentMode: .yang,
                onPillTapped: { _ in },
                onSaveChat: {}
            )
                .previewLayout(.sizeThatFits)
                .padding()
                .background(Color.black)
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode (Loading)")
        }
    }
}
