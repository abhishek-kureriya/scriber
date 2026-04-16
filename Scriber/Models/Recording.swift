import Foundation

struct Recording: Identifiable {
    let id = UUID()
    let fileURL: URL
    let date: Date
    var duration: TimeInterval
    var transcript: String?
    var summary: String?
}
