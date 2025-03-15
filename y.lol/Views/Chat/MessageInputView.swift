import SwiftUI

struct MessageInputView: View {
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

                        // Attachment buttons
            HStack(spacing: 16) {
                Button(action: { /* TODO: Handle @ mentions */ }) {
                    Image(systemName: "at")
                        .foregroundColor(.gray)
                }
                
                Button(action: { /* TODO: Handle attachments */ }) {
                    Image(systemName: "paperclip")
                        .foregroundColor(.gray)
                }
                
                Button(action: { /* TODO: Handle voice */ }) {
                    Image(systemName: "mic")
                        .foregroundColor(.gray)
                }
            }
            .padding(.leading, 12)
            
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(!messageText.isEmpty ? Color.accentColor : Color.gray.opacity(0.3))
            }
            .disabled(messageText.isEmpty)
            .padding(.trailing, 8)
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(20)
    }
} 