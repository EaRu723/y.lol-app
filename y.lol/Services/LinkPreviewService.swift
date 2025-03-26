//
//  LinkPreviewService.swift
//  y.lol
//
//  Created by Andrea Russo on 3/26/25.
//

import Foundation
import LinkPresentation

class LinkPreviewService {
    static let shared = LinkPreviewService()
    private var cache: [String: LPLinkMetadata] = [:]
    
    func loadMetadata(for urlString: String) async throws -> LPLinkMetadata {
        if let cached = cache[urlString] {
            return cached
        }
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let metadata = try await LPMetadataProvider().startFetchingMetadata(for: url)
        cache[urlString] = metadata
        return metadata
    }
    
    func clearCache() {
        cache.removeAll()
    }
}
