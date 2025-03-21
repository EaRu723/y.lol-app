import SwiftUI

struct MessageInputView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var messageText: String
    @FocusState private var isFocused: Bool
    @Binding var isActionsExpanded: Bool
    @Binding var selectedImage: UIImage?
    @State private var textEditorHeight: CGFloat = 36
    let onSend: () -> Void
    
    var onCameraButtonTapped: () -> Void
    var onPhotoLibraryButtonTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Image preview area
            if let selectedImage = selectedImage {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: 200, maxHeight: 200)
                        .cornerRadius(12)
                        .clipped()
                        .padding(.top, 4)
                    
                    Button(action: {
                        self.selectedImage = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                            .padding(6)
                    }
                }
                .padding(.horizontal)
            }
            
            ZStack(alignment: .top) {
                // Main input field
                HStack(spacing: 12) {
                    // Plus button moved outside the input field
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isActionsExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isActionsExpanded ? "chevron.up.circle.fill" : "plus.circle.fill")
                            .resizable()
                            .frame(width: 28, height: 28)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                    
                    // Text field with rounded corners and gray border
                    ZStack(alignment: .bottomTrailing) {
                        ZStack(alignment: .leading) {
                            // Invisible text view used to calculate height
                            Text(messageText.isEmpty ? "Ask anything..." : messageText)
                                .foregroundColor(.clear)
                                .padding(.horizontal, 12)
                                .lineLimit(5) // Maximum lines before scrolling
                                .background(GeometryReader { geometry in
                                    Color.clear.preference(
                                        key: ViewHeightKey.self,
                                        value: geometry.size.height + 16 // Add padding
                                    )
                                })
                            
                            // Placeholder text
                            if messageText.isEmpty {
                                Text("Ask anything...")
                                    .foregroundColor(.gray)
                                    .padding(.leading, 12)
                                    .frame(height: textEditorHeight)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            // Actual text editor
                            TextEditor(text: $messageText)
                                .padding(.horizontal, 8)
                                .frame(height: max(36, textEditorHeight))
                                .frame(minHeight: 40)
                                .background(Color.clear)
                                .scrollContentBackground(.hidden)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .focused($isFocused)
                                .padding(.trailing, 40) // Add padding for the send button
                        }
                        .onPreferenceChange(ViewHeightKey.self) { height in
                            self.textEditorHeight = height
                        }
                        
                        // Send button only appears when there's text or an image
                        if !messageText.isEmpty || selectedImage != nil {
                            Button(action: onSend) {
                                ZStack {
                                    Circle()
                                        .fill(colorScheme == .dark ? .white : .black)
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(colorScheme == .dark ? .black : .white)
                                }
                            }
                            .padding(.trailing, 8)
                            .padding(.bottom, 4)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(colorScheme == .dark ? Color.black : Color.white)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(colorScheme == .dark ? Color.gray.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 0.5)
                    )
                }
                
                // Action buttons popup
                if isActionsExpanded {
                    HStack(spacing: 16) {
                        Button(action: onCameraButtonTapped) {
                            Image(systemName: "camera")
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .frame(width: 40, height: 40)
                                .background(colorScheme == .dark ? Color.black : Color.white)
                                .overlay(
                                    Circle()
                                        .stroke(colorScheme == .dark ? Color.gray.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 0.5)
                                )
                                .clipShape(Circle())
                        }

                        Button(action: onPhotoLibraryButtonTapped) {
                            Image(systemName: "photo")
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .frame(width: 40, height: 40)
                                .background(colorScheme == .dark ? Color.black : Color.white)
                                .overlay(
                                    Circle()
                                        .stroke(colorScheme == .dark ? Color.gray.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 0.5)
                                )
                                .clipShape(Circle())
                        }
                        
                        Button(action: { /* TODO: Handle @ mentions */ }) {
                            Image(systemName: "at")
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .frame(width: 40, height: 40)
                                .background(colorScheme == .dark ? Color.black : Color.white)
                                .overlay(
                                    Circle()
                                        .stroke(colorScheme == .dark ? Color.gray.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 0.5)
                                )
                                .clipShape(Circle())
                        }
                        
                        Button(action: { /* TODO: Handle attachments */ }) {
                            Image(systemName: "paperclip")
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .frame(width: 40, height: 40)
                                .background(colorScheme == .dark ? Color.black : Color.white)
                                .overlay(
                                    Circle()
                                        .stroke(colorScheme == .dark ? Color.gray.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 0.5)
                                )
                                .clipShape(Circle())
                        }
                        
                        Button(action: { /* TODO: Handle voice */ }) {
                            Image(systemName: "mic")
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .frame(width: 40, height: 40)
                                .background(colorScheme == .dark ? Color.black : Color.white)
                                .overlay(
                                    Circle()
                                        .stroke(colorScheme == .dark ? Color.gray.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 0.5)
                                )
                                .clipShape(Circle())
                        }
                    }
                    .offset(y: -50) // Adjust this value to position the buttons above the text field
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedImage != nil)
        .padding(.horizontal)
        .padding(.vertical, 10)
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

// Helper for measuring text height
struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
