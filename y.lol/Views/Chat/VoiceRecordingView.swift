//
//  VoiceRecordingView.swift
//  y.lol
//
//  Created by Andrea Russo on 4/12/25.
//

import SwiftUI

struct VoiceRecordingView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var voiceViewModel: VoiceTranscriptionViewModel
    var onTranscriptComplete: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                
                Text("Recording...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
            }
            
        }
        .padding(.horizontal)
        .padding(.top, 4)
        .background(colorScheme == .dark ? Color.black : Color.white)
    }
} 