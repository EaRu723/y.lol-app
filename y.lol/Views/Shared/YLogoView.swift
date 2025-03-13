//
//  YLogoView.swift
//  y.lol
//
//  Created by Andrea Russo on 3/1/25.
//


//
//  y_lolApp.swift
//  y.lol
//
//  Created by Andrea Russo on 2/25/25.
//

import SwiftUI


struct YLogoView: View {
    @Environment(\.themeColors) private var colors
    let size: CGFloat
    let isLoading: Bool
    
    init(size: CGFloat = 40, isLoading: Bool = false) {
        self.size = size
        self.isLoading = isLoading
    }
    
    private var loadingGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(
                stops: [
                    .init(color: Color(hex: "FF5733"), location: 0.0),  // Bright orange-red
                    .init(color: Color(hex: "FFBD33"), location: 0.17), // Amber/gold
                    .init(color: Color(hex: "33FF57"), location: 0.33), // Bright green
                    .init(color: Color(hex: "33FFBD"), location: 0.5),  // Turquoise
                    .init(color: Color(hex: "3357FF"), location: 0.67), // Bright blue
                    .init(color: Color(hex: "BD33FF"), location: 0.83), // Purple
                    .init(color: Color(hex: "FF3390"), location: 1.0)   // Pink
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
                        AnyShapeStyle(colors.text(opacity: 0.8)),
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
                .font(YTheme.Typography.serif(size: size * 0.6, weight: .light))
                .foregroundColor(colors.text(opacity: 0.8))
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
    .withYTheme()
}
