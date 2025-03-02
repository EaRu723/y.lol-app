//
//  y_lolApp.swift
//  y.lol
//
//  Created by Andrea Russo on 2/25/25.
//

import SwiftUI

struct YLogoView: View {
    @Environment(\.colorScheme) private var colorScheme
    let size: CGFloat
    let isLoading: Bool
    
    init(size: CGFloat = 40, isLoading: Bool = false) {
        self.size = size
        self.isLoading = isLoading
    }
    
    private var colors: (text: Color, border: Color) {
        switch colorScheme {
        case .light:
            return (
                text: Color(hex: "2C2C2C").opacity(0.8),
                border: Color(hex: "2C2C2C").opacity(0.8)
            )
        case .dark:
            return (
                text: Color(hex: "F5F2E9").opacity(0.8),
                border: Color(hex: "F5F2E9").opacity(0.8)
            )
        @unknown default:
            return (
                text: Color(hex: "2C2C2C").opacity(0.8),
                border: Color(hex: "2C2C2C").opacity(0.8)
            )
        }
    }
    
    private var loadingGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(
                stops: [
                    .init(color: Color(hex: "E4D5B7"), location: 0.0),
                    .init(color: Color(hex: "2C2C2C"), location: 0.2),
                    .init(color: Color(hex: "E4D5B7"), location: 0.4),
                    .init(color: Color(hex: "2C2C2C"), location: 0.6),
                    .init(color: Color(hex: "E4D5B7"), location: 0.8),
                    .init(color: Color(hex: "2C2C2C"), location: 1.0)
                ]
            ),
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360)
        )
    }
    
    var body: some View {
        ZStack {
            // Circle border with optional rotating gradient
            Circle()
                .stroke(
                    isLoading ?
                    AnyShapeStyle(loadingGradient) :
                    AnyShapeStyle(colors.border),
                    lineWidth: 1.5
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(isLoading ? 360 : 0))
                .animation(
                    isLoading ?
                    .linear(duration: 2.0).repeatForever(autoreverses: false) :
                    .default,
                    value: isLoading
                )
            
            // Y text
            Text("Y")
                .font(.system(size: size * 0.6, weight: .light, design: .serif))
                .foregroundColor(colors.text)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        YLogoView(size: 40, isLoading: false)
        YLogoView(size: 40, isLoading: true)
        YLogoView(size: 60, isLoading: true)
            .preferredColorScheme(.dark)
    }
    .padding()
    .background(Color(hex: "F5F2E9"))
}
