import Foundation

/// Represents an AI-suggested keyword with confidence score
struct KeywordSuggestion: Identifiable, Hashable {
    let id = UUID()
    let keyword: String
    let confidence: Float  // 0.0 to 1.0

    var confidencePercentage: Int {
        Int(confidence * 100)
    }
}
