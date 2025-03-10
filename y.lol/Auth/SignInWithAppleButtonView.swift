//
//  SignInWithAppleButtonView.swift
//  y.lol
//
//  Created by Andrea Russo on 3/10/25.
//

import SwiftUI
import AuthenticationServices

public struct SignInWithAppleButtonView: View {
    public let type: ASAuthorizationAppleIDButton.ButtonType
    public let style: ASAuthorizationAppleIDButton.Style
    public let cornerRadius: CGFloat
    
    public init(
        type: ASAuthorizationAppleIDButton.ButtonType = .signIn,
        style: ASAuthorizationAppleIDButton.Style = .black,
        cornerRadius: CGFloat = 10
    ) {
        self.type = type
        self.style = style
        self.cornerRadius = cornerRadius
    }
    
    public var body: some View {
        ZStack {
            Color.black.opacity(0.001)
            
            SignInWithAppleButtonViewRepresentable(type: type, cornerRadius: cornerRadius)
                .disabled(true)
        }
    }
}

private struct SignInWithAppleButtonViewRepresentable: UIViewRepresentable {
    @Environment(\.colorScheme) var colorScheme

    let type: ASAuthorizationAppleIDButton.ButtonType
    private var buttonStyle: ASAuthorizationAppleIDButton.Style {
            colorScheme == .dark ? .white : .black
        }
    let cornerRadius: CGFloat
    
    func makeUIView(context: Context) -> some UIView {
        ASAuthorizationAppleIDButton(authorizationButtonType: type, authorizationButtonStyle: colorScheme == .dark ? .white : .black)
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
    
    func makeCoordinator() -> () {
        
    }
}

#Preview("SignInWithAppleButtonView") {
    ZStack {
        Color.black
        
        VStack(spacing: 4) {
            SignInWithAppleButtonView(
                type: .signIn,
                style: .white, cornerRadius: 30)
                .frame(height: 50)
                .background(Color.red)
        }
        .padding(40)
    }
}
