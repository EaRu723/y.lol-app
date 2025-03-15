import SwiftUI

struct MessageInputView: View {
    @Environment(\.themeColors) private var colors
    @Binding var messageText: String
    @FocusState private var isFocused: Bool
    @State private var isActionsExpanded = false
    let onSend: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Action buttons popup
            if isActionsExpanded {
                VStack(spacing: 16) {
                    Button(action: { /* TODO: Handle @ mentions */ }) {
                        Image(systemName: "at")
                            .foregroundColor(colors.text(opacity: 0.5))
                            .frame(width: 40, height: 40)
                            .background(colors.background)
                            .clipShape(Circle())
                    }
                    
                    Button(action: { /* TODO: Handle attachments */ }) {
                        Image(systemName: "paperclip")
                            .foregroundColor(colors.text(opacity: 0.5))
                            .frame(width: 40, height: 40)
                            .background(colors.background)
                            .clipShape(Circle())
                    }
                    
                    Button(action: { /* TODO: Handle voice */ }) {
                        Image(systemName: "mic")
                            .foregroundColor(colors.text(opacity: 0.5))
                            .frame(width: 40, height: 40)
                            .background(colors.background)
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom, 8)
                .padding(.trailing, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1)
            }
            
            // Main input field
            HStack(spacing: 12) {
                TextField("Ask anything...", text: $messageText, axis: .vertical)
                    .padding(.vertical, 8)
                    .padding(.leading, 12)
                    .focused($isFocused)
                    .frame(minHeight: 40)
                    .animation(.easeInOut(duration: 0.2), value: messageText)
                    .foregroundColor(colors.text(opacity: 0.5))
                
                // Toggle button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isActionsExpanded.toggle()
                    }
                }) {
                    Image(systemName: isActionsExpanded ? "chevron.down.circle.fill" : "plus.circle.fill")
                        .foregroundColor(colors.text(opacity: 0.5))
                        .rotationEffect(.degrees(isActionsExpanded ? 180 : 0))
                }
                
                Button(action: onSend) {
                    Image(systemName: "arrow.up.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(!messageText.isEmpty ? colors.text(opacity: 0.5) : colors.text(opacity: 0.3))
                }
                .disabled(messageText.isEmpty)
                .padding(.trailing, 8)
            }
            .padding(.vertical, 8)
            .background(colors.background)
            .cornerRadius(20)
        }
        // Close actions when text field gains focus
        .onChange(of: isFocused) { _, newValue in
            if newValue {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isActionsExpanded = false
                }
            }
        }
    }
} 
