import SwiftUI
import LinkPresentation

struct ContentCardView: View {
    let item: ContentItem
    
    var body: some View {
        VStack(alignment: .leading) {
            // Link preview instead of placeholder
            if let url = URL(string: item.url) {
                LinkPreviewView(url: url)
                    .frame(height: 180)
                    .cornerRadius(8)
            } else {
                // Fallback if URL is invalid
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
                    .aspectRatio(16/9, contentMode: .fit)
                    .cornerRadius(8)
            }
            
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

// UIViewRepresentable wrapper for LPLinkView
struct LinkPreviewView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> LPLinkView {
        let linkView = LPLinkView(url: url)
        
        // Start fetching metadata
        let provider = LPMetadataProvider()
        provider.startFetchingMetadata(for: url) { metadata, error in
            if let metadata = metadata {
                DispatchQueue.main.async {
                    linkView.metadata = metadata
                }
            }
        }
        
        return linkView
    }
    
    func updateUIView(_ uiView: LPLinkView, context: Context) {
        // Nothing to update
    }
} 