import SwiftUI

struct HomeView: View {
    @State private var isRefreshing = false
    @State private var showingProfile = false
    
    // Sample data for the grid
    let items = [
        ContentItem(id: 1, title: "Swift Programming", tags: ["coding", "iOS"], url: "https://developer.apple.com/swift/"),
        ContentItem(id: 2, title: "Machine Learning Basics", tags: ["AI", "tech"], url: "https://www.tensorflow.org/"),
        ContentItem(id: 3, title: "UI Design Principles", tags: ["design", "UX"], url: "https://developer.apple.com/design/"),
        ContentItem(id: 4, title: "SwiftUI Animations", tags: ["coding", "animation"], url: "https://developer.apple.com/xcode/swiftui/"),
        ContentItem(id: 5, title: "Productivity Hacks", tags: ["lifestyle", "work"], url: "https://todoist.com/productivity-methods"),
        ContentItem(id: 6, title: "Future of Tech", tags: ["tech", "future"], url: "https://www.wired.com/")
    ]
    
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
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(items) { item in
                            ContentCardView(item: item)
                        }
                    }
                    .padding()
                }
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