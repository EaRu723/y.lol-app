import SwiftUI

struct HomeView: View {
    @State private var isRefreshing = false
    @State private var showingProfile = false
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    // Add position data to each item
    let items = [
        ContentItem(id: 1, title: "Swift Programming", tags: ["coding", "iOS"], url: "https://developer.apple.com/swift/", position: CGPoint(x: 200, y: 150)),
        ContentItem(id: 2, title: "Machine Learning Basics", tags: ["AI", "tech"], url: "https://www.tensorflow.org/", position: CGPoint(x: 550, y: 200)),
        ContentItem(id: 3, title: "UI Design Principles", tags: ["design", "UX"], url: "https://developer.apple.com/design/", position: CGPoint(x: 300, y: 450)),
        ContentItem(id: 4, title: "SwiftUI Animations", tags: ["coding", "animation"], url: "https://developer.apple.com/xcode/swiftui/", position: CGPoint(x: 700, y: 350)),
        ContentItem(id: 5, title: "Productivity Hacks", tags: ["lifestyle", "work"], url: "https://todoist.com/productivity-methods", position: CGPoint(x: 900, y: 150)),
        ContentItem(id: 6, title: "Future of Tech", tags: ["tech", "future"], url: "https://www.wired.com/", position: CGPoint(x: 500, y: 600))
    ]
    
    // Optional: Add state for draggable positions
    @State private var positions: [Int: CGPoint] = [:]
    
    // Helper function to get position for an item
    private func getPosition(for item: ContentItem) -> CGPoint {
        // First check if there's a custom position from dragging
        if let dragPosition = positions[item.id] {
            return dragPosition
        }
        
        // Then check if the item has a predefined position
        if let definedPosition = item.position {
            return definedPosition
        }
        
        // Fallback to algorithmic positioning if no position is defined
        return CGPoint(
            x: CGFloat(100 + (item.id * 250) % 1200),
            y: CGFloat(100 + (item.id * 180) % 1000)
        )
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Add gradient background
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Replace grid with horizontal scrolling canvas
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    ZStack(alignment: .topLeading) {
                        // Canvas background
                        Color.clear
                            .frame(width: 1500, height: 1500)  // Large canvas size
                        
                        // Content items positioned on canvas
                        ForEach(items) { item in
                            ContentCardView(item: item)
                                .frame(width: 300)  // Fixed width for cards
                                .position(getPosition(for: item))
                                // Optional: Add draggable functionality
                                .gesture(
                                    DragGesture()
                                        .onChanged { gesture in
                                            positions[item.id] = gesture.location
                                        }
                                )
                        }
                    }
                    .frame(width: 1500, height: 1500)  // Match canvas size
                    .scaleEffect(scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / lastScale
                                lastScale = value
                                // Limit zoom range between 0.5 and 3.0
                                scale = min(max(scale * delta, 0.5), 3.0)
                            }
                            .onEnded { _ in
                                lastScale = 1.0
                            }
                    )
                }
                .background(Color.clear)
            }
            .navigationTitle("My Web")
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

#Preview {
    HomeView()
} 