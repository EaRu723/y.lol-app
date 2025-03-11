//
//  yinyang.swift
//  y.lol
//
//  Created by Andrea Russo on 3/8/25.
//

import SwiftUI

struct SimplifiedYinYangView: View {
    var size: CGFloat
    var colors: (light: Color, dark: Color)
    
    init(size: CGFloat = 200, lightColor: Color = .white, darkColor: Color = .black) {
        self.size = size
        self.colors = (lightColor, darkColor)
    }
    
    var body: some View {
        // This implementation uses GeometryReader to ensure proper sizing
        GeometryReader { geometry in
            let diameter = min(geometry.size.width, geometry.size.height)
            let radius = diameter / 2
            
            ZStack {
                // Base circle
                Circle()
                    .fill(colors.light)
                
                // Left half (dark)
                HalfCircle(color: colors.dark)
                
                // The two smaller circles
                Circle()
                    .fill(colors.dark)
                    .frame(width: diameter / 2, height: diameter / 2)
                    .offset(y: -diameter / 4)
                
                Circle()
                    .fill(colors.light)
                    .frame(width: diameter / 2, height: diameter / 2)
                    .offset(y: diameter / 4)
                
                // The two smallest dots
                Circle()
                    .fill(colors.light)
                    .frame(width: diameter / 6, height: diameter / 6)
                    .offset(y: -diameter / 4)
                
                Circle()
                    .fill(colors.dark)
                    .frame(width: diameter / 6, height: diameter / 6)
                    .offset(y: diameter / 4)
            }
            .frame(width: diameter, height: diameter)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(width: size, height: size)
    }
}

// Helper struct for creating half circles
struct HalfCircle: View {
    var color: Color
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.5)
            .fill(color)
            .rotationEffect(.degrees(90))
    }
}

struct YinYangLogoView: View {
    var size: CGFloat
    var isLoading: Bool
    var colors: (light: Color, dark: Color)
    
    @State private var rotation: Double = 0
    
    init(size: CGFloat = 40, isLoading: Bool = false,
         lightColor: Color = .white, darkColor: Color = .black) {
        self.size = size
        self.isLoading = isLoading
        self.colors = (lightColor, darkColor)
    }
    
    var body: some View {
        SimplifiedYinYangView(size: size, lightColor: colors.light, darkColor: colors.dark)
            .rotationEffect(.degrees(rotation))
            .onChange(of: isLoading) { _, newValue in
                if newValue {
                    // Start continuous rotation when loading
                    withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                } else {
                    // Stop rotation and reset when not loading
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        // Complete the current rotation to a multiple of 360
                        let currentRotationCycle = floor(rotation / 360)
                        rotation = (currentRotationCycle + 1) * 360
                    }
                }
            }
            .onAppear {
                // Initialize rotation if loading is true at the start
                if isLoading {
                    withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
            }
    }
}

// Preview struct
struct YinYangView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SimplifiedYinYangView(size: 200)
                .border(Color.gray, width: 1)
            
            YinYangLogoView(size: 100, isLoading: true)
                .border(Color.gray, width: 1)
            
            // Dark mode version
            SimplifiedYinYangView(size: 100, lightColor: Color(hex: "F5F2E9"), darkColor: Color(hex: "2C2C2C"))
                .padding()
                .background(Color.black)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
