//
//  TypingIndicatorView.swift
//  y.lol
//
//  Created by Andrea Russo on 3/11/25.
//

import SwiftUI

struct TypingIndicatorView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                BouncingDot(delay: Double(index) * 0.15)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            colorScheme == .dark ? Color.black : Color.white
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(colorScheme == .dark ? Color.gray.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 0.5)
        )
    }
}

private struct BouncingDot: View {
    @Environment(\.colorScheme) private var colorScheme
    let delay: Double
    
    @State private var offset: CGFloat = 0
    @State private var timer: Timer?
    
    var body: some View {
        Circle()
            .fill(colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.7))
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
            timer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    offset = -4
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        offset = 0
                    }
                }
            }
            timer?.fire()
        }
    }
}

// Preview provider
struct TypingIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TypingIndicatorView()
                .padding()
                .previewLayout(.sizeThatFits)
                .background(Color.white)
                .previewDisplayName("Light Mode")
            
            TypingIndicatorView()
                .padding()
                .previewLayout(.sizeThatFits)
                .background(Color.black)
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
