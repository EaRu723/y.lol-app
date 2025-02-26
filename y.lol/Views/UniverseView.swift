import SwiftUI

struct UniverseView: View {
    @State private var showingProfile = false
    
    // Sample data for the discovery grid
    let discoveryItems = [
        ContentItem(id: 7, title: "Trending Tech News", tags: ["trending", "tech"], url: "https://techcrunch.com/"),
        ContentItem(id: 8, title: "Popular Science", tags: ["science", "popular"], url: "https://www.popsci.com/"),
        ContentItem(id: 9, title: "Digital Art Gallery", tags: ["art", "digital"], url: "https://www.behance.net/"),
        ContentItem(id: 10, title: "Indie Game Showcase", tags: ["games", "indie"], url: "https://itch.io/"),
        ContentItem(id: 11, title: "Sustainable Living", tags: ["eco", "lifestyle"], url: "https://www.treehugger.com/"),
        ContentItem(id: 12, title: "Space Exploration", tags: ["space", "science"], url: "https://www.nasa.gov/")
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Add gradient background
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.orange.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(discoveryItems) { item in
                            ContentCardView(item: item)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Universe")
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
}

#Preview {
    UniverseView()
} 