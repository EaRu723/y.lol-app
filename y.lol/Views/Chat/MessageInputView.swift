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
            
            // Voice transcription view if recording
            if voiceViewModel.isRecording {
                VoiceRecordingView(
                    voiceViewModel: voiceViewModel,
                    onTranscriptComplete: { transcript in
                        appendTranscriptToMessage(transcript)
                    }
                )
            }
            
            // Input bar with rounded corners
            HStack(spacing: 12) {
                // Plus/Toggle button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showAttachmentButtons.toggle()
                        // Optionally hide keyboard if buttons are shown
                        // if showAttachmentButtons { isFocused = false }
                    }
                }) {
                    Image(systemName: showAttachmentButtons ? "chevron.left.circle.fill" : "plus.circle.fill")
                        .resizable()
                        .frame(width: 28, height: 28)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }

                // Conditionally show attachment buttons inline
                if showAttachmentButtons {
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
                    
                    // Replace the complex Group with a function call
                    actionButton
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
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: voiceViewModel.isRecording)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showAttachmentButtons)
        // Add onChange modifier for messageText
        .onChange(of: messageText) { _, newValue in
            if !newValue.isEmpty && showAttachmentButtons {
                showAttachmentButtons = false
            }
        }
        // Add onChange modifier for isFocused
        .onChange(of: isFocused) { _, newValue in
            if newValue && showAttachmentButtons {
                showAttachmentButtons = false
            }
        }
    }
    
    // Add this computed property to simplify the view
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
