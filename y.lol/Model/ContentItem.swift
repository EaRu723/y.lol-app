import Foundation

struct ContentItem: Identifiable {
    let id: Int
    let title: String
    let tags: [String]
    let url: String
    let position: CGPoint?
}