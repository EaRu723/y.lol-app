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

#Preview {
    ContentView()
} 
