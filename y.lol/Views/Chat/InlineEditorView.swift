//
//  InlineEditorView.swift
//  y.lol
//
//  Created by Andrea Russo on 3/11/25.
//

import SwiftUI

struct InlineEditorView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var text: String
    @Binding var isEditing: Bool
    @FocusState var isFocused: Bool
    var onSend: () -> Void
    let hapticService: HapticService
    
    var body: some View {
        VStack(spacing: 0) {
            TextEditor(text: $text)
                .focused($isFocused)
                .frame(minHeight: 36, maxHeight: 120)
                .font(YTheme.Typography.body)
                .foregroundColor(colorScheme == .light ?
                    Color(hex: "2C2C2C").opacity(0.9) :
                    Color(hex: "F5F2E9").opacity(0.9))
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .padding(.vertical, 8)
                .padding(.horizontal, 20)
                .onChange(of: text) { oldValue, newValue in
                    if newValue.count > oldValue.count {
                        hapticService.playTypingFeedback()
                    }
                }
                .onAppear {
                    isFocused = true
                }
                .onTapGesture {
                    isEditing = true
                }
            Spacer()
            // Custom toolbar view
//            KeyboardToolbarView(text: $text, onSend: onSend, hapticService: hapticService)
//                .padding(.horizontal)
//                .padding(.bottom, 8)
//                .background(colors.background)
        }
        .background(colors.background)
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

struct InlineEditorView_Previews: PreviewProvider {
    static var previews: some View {
        // Mock dependencies for preview
        struct PreviewWrapper: View {
            @State private var text = "Type something here..."
            @State private var isEditing = false
            
            var body: some View {
                VStack {
                    InlineEditorView(
                        text: $text,
                        isEditing: $isEditing,
                        onSend: { print("Message sent") },
                        hapticService: MockHapticService()
                    )
                }
                .padding()
                .background(Color(hex: "F5F2E9"))
            }
        }
        
        return Group {
            PreviewWrapper()
                .previewDisplayName("Light Mode")
            
            PreviewWrapper()
                .preferredColorScheme(.dark)
                .background(Color(hex: "1C1C1E"))
                .previewDisplayName("Dark Mode")
        }
    }
}

// Mock service for preview purposes
private class MockHapticService: HapticService {
    override func playTypingFeedback() {
        // No-op for preview
    }
}
