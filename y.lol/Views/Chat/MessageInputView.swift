import SwiftUI

struct MessageInputView: View {
    @Environment(\.themeColors) private var colors
    @Binding var messageText: String
    @FocusState private var isFocused: Bool
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("Ask anything...", text: $messageText, axis: .vertical)
                .padding(.vertical, 8)
                .padding(.leading, 12)
                .focused($isFocused)
                .frame(minHeight: 40)
                .animation(.easeInOut(duration: 0.2), value: messageText)
                .foregroundColor(colors.text(opacity: 0.5))

            // Attachment buttons
            HStack(spacing: 16) {
                Button(action: { /* TODO: Handle @ mentions */ }) {
                    Image(systemName: "at")
                        .foregroundColor(colors.text(opacity: 0.5))
                }
                
                Button(action: { /* TODO: Handle attachments */ }) {
                    Image(systemName: "paperclip")
                        .foregroundColor(colors.text(opacity: 0.5))
                }
                
                Button(action: { /* TODO: Handle voice */ }) {
                    Image(systemName: "mic")
                        .foregroundColor(colors.text(opacity: 0.5))
                }
            }
            .padding(.leading, 12)
            
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
} 
