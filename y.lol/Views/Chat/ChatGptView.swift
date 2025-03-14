//
//  ChatGptView.swift
//  y.lol
//
//  Created by Andrea Russo on 3/13/25.
//

import SwiftUI

struct ChatInputView: View {
    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                TextField("Message", text: $text, axis: .vertical)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .focused($isFocused)
                    .frame(minHeight: 40)
                    .animation(.easeInOut(duration: 0.2), value: text)
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.black)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .onAppear {
                DispatchQueue.main.async {
                    isFocused = true
                }
            }
        }
    }
    
    func sendMessage() {
        print("Message Sent: \(text)")
        text = ""
    }
}

struct ChatInputView_Previews: PreviewProvider {
    static var previews: some View {
        ChatInputView()
    }
}
