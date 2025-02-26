import SwiftUI
import LinkPresentation

struct ContentCardView: View {
    let item: ContentItem
    @State private var previewHeight: CGFloat = 120
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Link preview with better sizing and loading state
            if let url = URL(string: item.url) {
                ZStack {
                    LinkPreviewView(url: url, onMetadataLoaded: { _ in
                        isLoading = false
                    })
                    .frame(height: previewHeight)
                    .cornerRadius(8)
                    .clipped()
                    
                    if isLoading {
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            )
                    }
                }
            } else {
                // Fallback if URL is invalid
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(height: 120)
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

// Improved UIViewRepresentable wrapper for LPLinkView
struct LinkPreviewView: UIViewRepresentable {
    let url: URL
    var onMetadataLoaded: ((LPLinkMetadata) -> Void)?
    
    func makeUIView(context: Context) -> LPLinkView {
        let linkView = LPLinkView(url: url)
        
        // Configure the link view for compact display
        // Note: sizeToFit() is called in updateUIView which is guaranteed to run on the main thread
        
        // Start fetching metadata
        let provider = LPMetadataProvider()
        provider.startFetchingMetadata(for: url) { metadata, error in
            if let metadata = metadata {
                Task { @MainActor in
                    // Apply custom styling to metadata if needed
                    linkView.metadata = metadata
                    linkView.sizeToFit()
                    onMetadataLoaded?(metadata)
                }
            }
        }
        
        return linkView
    }
    
    func updateUIView(_ uiView: LPLinkView, context: Context) {
        // Apply custom styling
        uiView.backgroundColor = .clear
        
        // Force compact display mode
        if let effectView = findVisualEffectView(in: uiView) {
            effectView.effect = UIBlurEffect(style: .regular)
        }
        
        // Ensure proper sizing on the main thread
        uiView.sizeToFit()
    }
    
    // Helper method to find and customize the visual effect view
    private func findVisualEffectView(in view: UIView) -> UIVisualEffectView? {
        if let visualEffectView = view as? UIVisualEffectView {
            return visualEffectView
        }
        
        for subview in view.subviews {
            if let found = findVisualEffectView(in: subview) {
                return found
            }
        }
        
        return nil
    }
}

// Custom LPLinkView that forces compact mode
class CompactLPLinkView: LPLinkView {
    @MainActor
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.layoutFittingExpandedSize.width, height: 120)
    }
    
    @MainActor
    override func sizeToFit() {
        super.sizeToFit()
        // Additional customization after sizing if needed
        frame.size.height = min(frame.size.height, 120)
    }
} 