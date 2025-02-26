import SwiftUI

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