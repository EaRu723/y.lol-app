//
//  ActionButtonsView.swift
//  y.lol
//
//  Created by Andrea Russo on 3/27/25.
//

import Foundation
import SwiftUI

struct ChatInputButtonsView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @Binding var messageText: String
    @StateObject private var voiceViewModel = VoiceTranscriptionViewModel()
    
    var onCameraButtonTapped: () -> Void = {}
    var onPhotoLibraryButtonTapped: () -> Void = {}
    
    var body: some View {
        VStack(spacing: 8) {
            // Voice transcription status if recording
            if voiceViewModel.isRecording {
                VoiceRecordingView(
                    voiceViewModel: voiceViewModel,
                    onTranscriptComplete: { transcript in
                        appendTranscript(transcript)
                    }
                )
            }
            
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
                
//                Button(action: { 
//                    messageText += "@huxley "
//                }) {
//                    Image(systemName: "at")
//                        .foregroundColor(colorScheme == .dark ? .white : .black)
//                        .frame(width: 40, height: 40)
//                        .background(colorScheme == .dark ? Color.black : Color.white)
//                        .overlay(
//                            Circle()
//                                .stroke(colorScheme == .dark ? Color.gray.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 0.5)
//                        )
//                        .clipShape(Circle())
//                }
                
//                Button(action: { /* TODO: Handle attachments */ }) {
//                    Image(systemName: "paperclip")
//                        .foregroundColor(colorScheme == .dark ? .white : .black)
//                        .frame(width: 40, height: 40)
//                        .background(colorScheme == .dark ? Color.black : Color.white)
//                        .overlay(
//                            Circle()
//                                .stroke(colorScheme == .dark ? Color.gray.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 0.5)
//                        )
//                        .clipShape(Circle())
//                }
                
//                Button(action: toggleRecording) {
//                    Image(systemName: voiceViewModel.isRecording ? "stop.fill" : "mic")
//                        .foregroundColor(voiceViewModel.isRecording ? .red : (colorScheme == .dark ? .white : .black))
//                        .frame(width: 40, height: 40)
//                        .background(colorScheme == .dark ? Color.black : Color.white)
//                        .overlay(
//                            Circle()
//                                .stroke(
//                                    voiceViewModel.isRecording ? Color.red : (colorScheme == .dark ? Color.gray.opacity(0.5) : Color.gray.opacity(0.3)), 
//                                    lineWidth: voiceViewModel.isRecording ? 1.5 : 0.5
//                                )
//                        )
//                        .clipShape(Circle())
//                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
    
    private func toggleRecording() {
        if voiceViewModel.isRecording {
            voiceViewModel.stopRecording()
            if !voiceViewModel.transcript.isEmpty {
                appendTranscript(voiceViewModel.transcript)
            }
        } else {
            voiceViewModel.startRecording()
        }
    }
    
    // Helper method to append transcript with proper spacing
    private func appendTranscript(_ transcript: String) {
        // Check if we need to add a space first
        if !messageText.isEmpty && !messageText.hasSuffix(" ") {
            messageText += " "
        }
        
        // Append the transcript
        messageText += transcript
    }
}
