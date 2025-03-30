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

                // Chat mode buttons with YinYang
                ChatHeaderButtons(
                    currentMode: currentMode,
                    onPillTapped: { mode in
                        onPillTapped(mode)
                    },
                    showButtons: showButtons && !isSearching,
                    isThinking: isThinking,
                    onCenterTapped: {
                        withAnimation {
                            showButtons.toggle()
                        }
                    }
                )
                .opacity(isSearching ? 0 : 1)
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
        .transition(
            .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
    }

    private func getShadowColor(for mode: FirebaseManager.ChatMode, isSelected: Bool) -> Color {
        guard isSelected else { return .clear }
        switch mode {
        case .yin: return Color.blue.opacity(0.5)
        case .yang: return Color.red.opacity(0.5)
        }
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
                        .fill(
                            colorScheme == .dark
                                ? Color.black.opacity(0.3) : Color.gray.opacity(0.1))
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
                onPillTapped: { _ in }
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
                onPillTapped: { _ in }
            )
            .previewLayout(.sizeThatFits)
            .padding()
            .background(Color.black)
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode (Loading)")
        }
    }
}
