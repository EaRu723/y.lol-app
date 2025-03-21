//
//  InlineEditorView.swift
//  y.lol
//
//  Created by Andrea Russo on 3/11/25.
//

import SwiftUI

struct InlineEditorView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.themeColors) private var colors
    @Binding var text: String
    @Binding var isEditing: Bool
    @FocusState var isFocused: Bool
    @State private var textEditorHeight: CGFloat = 36
    var onSend: () -> Void
    let hapticService: HapticService
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Text editor container
                HStack(alignment: .bottom) {
                    ZStack(alignment: .leading) {
                        // Invisible text view to calculate height
                        Text(text.isEmpty ? "Add comment or Send" : text)
                            .foregroundColor(.clear)
                            .padding(.horizontal, 12)
                            .lineLimit(5)
                            .background(GeometryReader { geometry in
                                Color.clear.preference(
                                    key: ViewHeightKey.self,
                                    value: geometry.size.height + 16
                                )
                            })
                        
                        // Placeholder
                        if text.isEmpty {
                            Text("Add comment or Send")
                                .foregroundColor(.gray)
                                .padding(.leading, 12)
                                .frame(height: textEditorHeight)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // Actual text editor
                        TextEditor(text: $text)
                            .focused($isFocused)
                            .frame(minHeight: 36, maxHeight: 120)
                            .frame(height: max(36, textEditorHeight))
                            .font(.body)
                            .foregroundColor(colors.text)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .padding(.horizontal, 8)
                            .onChange(of: text) { oldValue, newValue in
                                if newValue.count > oldValue.count {
                                    hapticService.playTypingFeedback()
                                }
                            }
                    }
                    .onPreferenceChange(ViewHeightKey.self) { height in
                        self.textEditorHeight = height
                    }
                    
                    // Send button
                    if !text.isEmpty {
                        Button(action: onSend) {
                            ZStack {
                                Circle()
                                    .fill(colors.accent)
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(colors.background)
                            }
                        }
                        .padding(.trailing, 8)
                        .padding(.bottom, 4)
                        .transition(.opacity)
                    }
                }
                .padding(.vertical, 4)
                .background(colors.background)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(colorScheme == .dark ? Color.gray.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 0.5)
                )
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(colors.background)
            .onAppear {
                isFocused = true
            }
            .onTapGesture {
                isEditing = true
            }
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
                .background(Color.white)
            }
        }
        
        return Group {
            PreviewWrapper()
                .previewDisplayName("Light Mode")
            
            PreviewWrapper()
                .preferredColorScheme(.dark)
                .background(Color.black)
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
