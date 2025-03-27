import SwiftUI

struct MessageInputView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var messageText: String
    @FocusState private var isFocused: Bool
    @Binding var isActionsExpanded: Bool
    @Binding var selectedImage: UIImage?
    @State private var textEditorHeight: CGFloat = 36
    @EnvironmentObject var firebaseManager: FirebaseManager
    @StateObject private var viewModel = ChatViewModel()
    
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
                            .background(Circle().fill(Color.black.opacity(0.5)))
                            .padding(6)
                    }
                }
                .padding(.horizontal)
            }
            
            // Action buttons popup
            if isActionsExpanded {
                ChatInputButtonsView(
                    messageText: $messageText,
                    onCameraButtonTapped: onCameraButtonTapped,
                    onPhotoLibraryButtonTapped: onPhotoLibraryButtonTapped
                )
            }
            
            // Input bar with rounded corners
            HStack(spacing: 12) {
                // Plus button on the left
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isActionsExpanded.toggle()
                    }
                }) {
                    Image(systemName: isActionsExpanded ? "chevron.down.circle.fill" : "plus.circle.fill")
                        .resizable()
                        .frame(width: 28, height: 28)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
                
                // Text field with rounded corners and gray border
                HStack(alignment: .bottom) {
                    ZStack(alignment: .leading) {
                        // Invisible text view used to calculate height
                        Text(messageText.isEmpty ? "Ask anything..." : messageText)
                            .foregroundColor(.clear)
                            .padding(.horizontal, 12)
                            .lineLimit(5)
                            .background(GeometryReader { geometry in
                                Color.clear.preference(
                                    key: ViewHeightKey.self,
                                    value: geometry.size.height + 16
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
                        
                        TextEditor(text: $messageText)
                            .padding(.horizontal, 8)
                            .frame(height: max(36, textEditorHeight))
                            .background(Color.clear)
                            .scrollContentBackground(.hidden)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .focused($isFocused)
                    }
                    .onPreferenceChange(ViewHeightKey.self) { height in
                        self.textEditorHeight = height
                    }
                    
                    // Send button with loading spinner
                    if !messageText.isEmpty || selectedImage != nil {
                        Button(action: onSend) {
                            sendButtonContent
                        }
                        .padding(.trailing, 8)
                        .padding(.bottom, 4)
                        .transition(.opacity)
                    }
                }
                .padding(.vertical, 4)
                .background(colorScheme == .dark ? Color.black : Color.white)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(colorScheme == .dark ? Color.gray.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 0.5)
                )
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(colorScheme == .dark ? Color.black : Color.white)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedImage != nil)
        .onChange(of: isFocused) { _, newValue in
            if newValue {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isActionsExpanded = false
                }
            }
        }
    }
    
    // Computed property for the send button content
    private var sendButtonContent: some View {
        ZStack {
            Circle()
                .fill(colorScheme == .dark ? Color.white : Color.black)
                .frame(width: 32, height: 32)
            
            if viewModel.isUploadingImage {
                ProgressView()
                    .progressViewStyle(
                        CircularProgressViewStyle(
                            tint: colorScheme == .dark ? Color.black : Color.white
                        )
                    )
                    .scaleEffect(0.8)
            } else {
                Image(systemName: "arrow.up")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? Color.black : Color.white)
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
