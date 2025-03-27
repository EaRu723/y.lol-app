//
//  VoiceTranscriptionViewModel.swift
//  y.lol
//
//  Created by Andrea Russo on 4/12/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class VoiceTranscriptionViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var transcript = ""
    
    private var speechRecognizer = SpeechRecognizer()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Setup binding to observe transcript changes from the speech recognizer
        setupTranscriptBinding()
    }
    
    private func setupTranscriptBinding() {
        // Monitor the transcript property of the speech recognizer
        Task {
            for await newTranscript in await speechRecognizer.$transcript.values {
                self.transcript = newTranscript
            }
        }
    }
    
    func startRecording() {
        Task {
            isRecording = true
            await speechRecognizer.startTranscribing()
        }
    }
    
    func stopRecording() {
        Task {
            isRecording = false
            await speechRecognizer.stopTranscribing()
        }
    }
    
    func reset() {
        Task {
            transcript = ""
            await speechRecognizer.resetTranscript()
        }
    }
} 