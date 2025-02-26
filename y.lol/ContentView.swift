import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "message")
                }
            
            UniverseView()
                .tabItem {
                    Label("Universe", systemImage: "globe")
                }
        }
    }
}

// MARK: - Home View
struct HomeView: View {
    @State private var isRefreshing = false
    
    // Sample data for the grid
    let items = [
        ContentItem(id: 1, title: "Swift Programming", tags: ["coding", "iOS"]),
        ContentItem(id: 2, title: "Machine Learning Basics", tags: ["AI", "tech"]),
        ContentItem(id: 3, title: "UI Design Principles", tags: ["design", "UX"]),
        ContentItem(id: 4, title: "SwiftUI Animations", tags: ["coding", "animation"]),
        ContentItem(id: 5, title: "Productivity Hacks", tags: ["lifestyle", "work"]),
        ContentItem(id: 6, title: "Future of Tech", tags: ["tech", "future"])
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(items) { item in
                        ContentCardView(item: item)
                    }
                }
                .padding()
            }
            .navigationTitle("My Web")
            .refreshable {
                // Simulate refresh
                isRefreshing = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    isRefreshing = false
                }
            }
        }
    }
}

// MARK: - Chat View
struct ChatView: View {
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []
    
    var body: some View {
        NavigationView {
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
            }
            .navigationTitle("Chat")
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

// MARK: - Universe View
struct UniverseView: View {
    // Sample data for the discovery grid
    let discoveryItems = [
        ContentItem(id: 7, title: "Trending Tech News", tags: ["trending", "tech"]),
        ContentItem(id: 8, title: "Popular Science", tags: ["science", "popular"]),
        ContentItem(id: 9, title: "Digital Art Gallery", tags: ["art", "digital"]),
        ContentItem(id: 10, title: "Indie Game Showcase", tags: ["games", "indie"]),
        ContentItem(id: 11, title: "Sustainable Living", tags: ["eco", "lifestyle"]),
        ContentItem(id: 12, title: "Space Exploration", tags: ["space", "science"])
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(discoveryItems) { item in
                        ContentCardView(item: item)
                    }
                }
                .padding()
            }
            .navigationTitle("Universe")
        }
    }
}

// MARK: - Supporting Views and Models

struct ContentItem: Identifiable {
    let id: Int
    let title: String
    let tags: [String]
}

struct ContentCardView: View {
    let item: ContentItem
    
    var body: some View {
        VStack(alignment: .leading) {
            // Placeholder image
            Rectangle()
                .fill(Color.blue.opacity(0.3))
                .aspectRatio(16/9, contentMode: .fit)
                .cornerRadius(8)
            
            Text(item.title)
                .font(.headline)
                .lineLimit(2)
            
            // Tags
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(item.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                    }
                }
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ChatMessage: Identifiable {
    let id: UUID
    let content: String
    let isUser: Bool
}

struct ChatBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            Text(message.content)
                .padding(12)
                .background(message.isUser ? Color.blue : Color(.systemGray5))
                .foregroundColor(message.isUser ? .white : .primary)
                .cornerRadius(16)
                .frame(maxWidth: 280, alignment: message.isUser ? .trailing : .leading)
            
            if !message.isUser {
                Spacer()
            }
        }
    }
}

#Preview {
    ContentView()
} 