import SwiftUI

struct ChatView: View {
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []
    @State private var showingProfile = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Add gradient background
                LinearGradient(
                    gradient: Gradient(colors: [Color.green.opacity(0.1), Color.blue.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack {
                    // Chat messages
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                ChatBubbleView(message: message)
                            }
                        }
                        .padding()
                    }
                    
                    // Input area
                    HStack {
                        TextField("Type a message...", text: $messageText)
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(20)
                        
                        Button(action: sendMessage) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground).opacity(0.8))
                }
            }
            .navigationTitle("Chat")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingProfile = true
                    }) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 22))
                    }
                }
            }
            .sheet(isPresented: $showingProfile) {
                ProfileDetailView()
            }
        }
    }
    
    func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        // Add user message
        let userMessage = ChatMessage(id: UUID(), content: messageText, isUser: true)
        messages.append(userMessage)
        
        // Simulate AI response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let responseMessage = ChatMessage(id: UUID(), content: "This is a placeholder response. In the final app, this would be an actual LLM response.", isUser: false)
            messages.append(responseMessage)
        }
        
        messageText = ""
    }
}

#Preview {
    ChatView()
} 