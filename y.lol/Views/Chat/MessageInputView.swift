import SwiftUI

struct MessageInputView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var messageText: String
    @FocusState private var isFocused: Bool
    @Binding var selectedImage: UIImage?
    @State private var textEditorHeight: CGFloat = 36
    @State private var showAttachmentButtons: Bool = false
    @EnvironmentObject var firebaseManager: FirebaseManager
    @StateObject private var viewModel = ChatViewModel()
    @StateObject private var voiceViewModel = VoiceTranscriptionViewModel()
    
    let onSend: () -> Void
    var onCameraButtonTapped: () -> Void
    var onPhotoLibraryButtonTapped: () -> Void
    let mode: FirebaseManager.ChatMode
    
    var body: some View {
        mainContent
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedImage != nil)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: voiceViewModel.isRecording)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showAttachmentButtons)
            .onChange(of: messageText) { _, newValue in
                if !newValue.isEmpty && showAttachmentButtons {
                    showAttachmentButtons = false
                }
            }
            .onChange(of: isFocused) { _, newValue in
                if newValue && showAttachmentButtons {
                    showAttachmentButtons = false
                }
            }
            .background(colorScheme == .dark ? Color.black.opacity(0.96) : Color.white.opacity(0.96))
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .ignoresSafeArea(.container, edges: .bottom)
    }
    
    // Break up the body into smaller components
    private var mainContent: some View {
        VStack(spacing: 0) {
            suggestionArea
            imagePreviewArea
            voiceTranscriptionArea
            inputBar
        }
    }
    
    private var suggestionArea: some View {
        HStack {
            SuggestionButton(mode: mode) { suggestion in
                if messageText.isEmpty {
                    messageText = suggestion
                } else {
                    messageText += " " + suggestion
                }
            }
            .padding(.leading)
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private var imagePreviewArea: some View {
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
    }
    
    @ViewBuilder
    private var voiceTranscriptionArea: some View {
        if voiceViewModel.isRecording {
            VoiceRecordingView(
                voiceViewModel: voiceViewModel,
                onTranscriptComplete: { transcript in
                    appendTranscriptToMessage(transcript)
                }
            )
        }
    }
    
    private var inputBar: some View {
        HStack(spacing: 12) {
            toggleButton
            
            // Conditionally show attachment buttons
            if showAttachmentButtons {
                attachmentButtons
            }
            
            // Text input field area
            textInputArea
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(colorScheme == .dark ? Color.black.opacity(0.96) : Color.white.opacity(0.96))
    }
    
    private var toggleButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showAttachmentButtons.toggle()
            }
        }) {
            Image(systemName: showAttachmentButtons ? "chevron.left.circle.fill" : "plus.circle.fill")
                .resizable()
                .frame(width: 28, height: 28)
                .foregroundColor(colorScheme == .dark ? .white : .black)
        }
    }
    
    private var attachmentButtons: some View {
        HStack {
            // Camera button
            Button(action: onCameraButtonTapped) {
                Image(systemName: "camera")
                    .frame(width: 28, height: 28)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
            .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
            
            // Photo library button
            Button(action: onPhotoLibraryButtonTapped) {
                Image(systemName: "photo")
                    .frame(width: 28, height: 28)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
            .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
        }
    }
    
    private var textInputArea: some View {
        HStack(alignment: .bottom) {
            textEditorStack
            actionButton
        }
        .padding(.vertical, 4)
        .background(colorScheme == .dark ? Color.black.opacity(0.96) : Color.white.opacity(0.96))
        .foregroundColor(colorScheme == .dark ? .white : .black)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(colorScheme == .dark ? Color.gray.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 0.5)
        )
    }
    
    private var textEditorStack: some View {
        ZStack(alignment: .leading) {
            // Height calculator
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
            
            // Placeholder
            if messageText.isEmpty {
                Text("Ask anything...")
                    .foregroundColor(.gray)
                    .padding(.leading, 12)
                    .frame(height: textEditorHeight)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Actual editor
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
    }
    
    // Action button logic remains the same
    @ViewBuilder
    private var actionButton: some View {
        if messageText.isEmpty && selectedImage == nil && !voiceViewModel.isRecording {
            // Mic button
            micButton
        } else if voiceViewModel.isRecording {
            // Stop recording button
            stopRecordingButton
        } else if !messageText.isEmpty || selectedImage != nil {
            // Send button
            sendButton
        }
    }

    @ViewBuilder
    private var micButton: some View {
        Button(action: { voiceViewModel.startRecording() }) {
            Image(systemName: "mic")
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .frame(width: 28, height: 28)
        }
        .padding(.trailing, 8)
        .padding(.bottom, 4)
        .transition(.opacity)
    }

    @ViewBuilder
    private var stopRecordingButton: some View {
        Button(action: {
            voiceViewModel.stopRecording()
            if !voiceViewModel.transcript.isEmpty {
                appendTranscriptToMessage()
            }
        }) {
            Image(systemName: "stop.fill")
                .foregroundColor(.red)
                .frame(width: 28, height: 28)
        }
        .padding(.trailing, 8)
        .padding(.bottom, 4)
        .transition(.opacity)
    }

    @ViewBuilder
    private var sendButton: some View {
        Button(action: onSend) {
            sendButtonContent
        }
        .padding(.trailing, 8)
        .padding(.bottom, 4)
        .transition(.opacity)
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

    // Updated helper function to accept transcript as parameter
    private func appendTranscriptToMessage(_ transcript: String = "") {
        let textToAppend = transcript.isEmpty ? voiceViewModel.transcript : transcript
        
        // Only proceed if there's something to append
        if !textToAppend.isEmpty {
            // Check if we need to add a space first
            if !messageText.isEmpty && !messageText.hasSuffix(" ") {
                messageText += " "
            }
            
            // Append the transcript
            messageText += textToAppend
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
