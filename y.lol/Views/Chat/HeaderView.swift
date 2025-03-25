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
        ZStack(alignment: .leading) {
            // Main header content
            HStack {
                // Search button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isSearching.toggle()
                    }
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                }
                .opacity(showButtons && !isSearching ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: showButtons)
                .zIndex(2)
                
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
                .opacity(showButtons && !isSearching ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: showButtons)
                .animation(.easeInOut(duration: 0.2), value: isSearching)
                
                Spacer(minLength: 8)
                
                // Center logo/emoji button
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
                    } else if showButtons && !isSearching {
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
                .opacity(isSearching ? 0 : 1)
                .animation(.easeInOut(duration: 0.2), value: isSearching)
                
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
                .opacity(showButtons && !isSearching ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: showButtons)
                .animation(.easeInOut(duration: 0.2), value: isSearching)
                
                Spacer()
                
                // Profile button
                Button(action: {
                    // Profile action - show profile sheet
                    showProfile = true
                }) {
                    Image(systemName: "person.circle")
                        .font(.system(size: 20))
                        .foregroundColor(colors.text)
                }
                .opacity(showButtons && !isSearching ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: showButtons)
                .animation(.easeInOut(duration: 0.2), value: isSearching)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .zIndex(1)
            
            // Inline search component that spawns from the search icon
            if isSearching {
                inlineSearchView()
                    .zIndex(3)
            }
        }
        .background(colors.background)
    }
    
    @ViewBuilder
    private func inlineSearchView() -> some View {
        HStack(spacing: 12) {
            // Search icon (fixed in place)
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isSearching.toggle()
                }
            }) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
            }
            .padding(.leading, 20)
            
            // Embedded compact search field
            InlineSearchField(isSearching: $isSearching) { searchText in
                // Handle search here
                print("Searching for: \(searchText)")
            }
            
            Spacer()
        }
        .frame(height: 44)
        .background(colors.background)
        .transition(.asymmetric(
            insertion: .move(edge: .leading).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
}

// New component for the inline search field
struct InlineSearchField: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isSearching: Bool
    @State private var searchText: String = ""
    @FocusState private var isFocused: Bool
    var onSearch: (String) -> Void
    
    var body: some View {
        HStack {
            // Text field
            TextField("Search conversations...", text: $searchText)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.gray.opacity(0.1))
                )
                .focused($isFocused)
                .onSubmit {
                    onSearch(searchText)
                }
            
            // Cancel button
            Button("Cancel") {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isSearching = false
                }
            }
            .foregroundColor(.primary)
            .padding(.trailing, 20)
        }
        .transition(.move(edge: .trailing).combined(with: .opacity))
        .onAppear {
            // Focus the search field when it appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
            }
        }
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
