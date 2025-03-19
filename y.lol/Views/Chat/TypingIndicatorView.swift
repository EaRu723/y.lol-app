//
//  TypingIndicatorView.swift
//  y.lol
//
//  Created by Andrea Russo on 3/11/25.
//

import SwiftUI

struct TypingIndicatorView: View {
    @Environment(\.themeColors) private var colors
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                BouncingDot(delay: Double(index) * 0.15)
            }
        }
        .padding(10)
        .background(colors.aiMessageBubble)
        .cornerRadius(16)
    }
}

private struct BouncingDot: View {
    @Environment(\.themeColors) private var colors
    let delay: Double
    
    @State private var offset: CGFloat = 0
    @State private var timer: Timer?
    
    var body: some View {
        Circle()
            .fill(colors.aiMessageText)
            .frame(width: 6, height: 6)
            .opacity(0.8)
            .offset(y: offset)
            .onAppear {
                startAnimation()
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
    }
    
    private func startAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            // Create a timer that fires every 0.6 seconds
            timer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    offset = -5
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        offset = 0
                    }
                }
            }
            
            // Trigger the timer immediately
            timer?.fire()
        }
    }
}

// Preview provider
struct TypingIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        TypingIndicatorView()
            .padding()
            .previewLayout(.sizeThatFits)
    }
} 