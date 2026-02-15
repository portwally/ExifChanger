import Foundation
import Vision
import AppKit

/// Service for AI-based image classification using Apple's Vision framework
final class VisionService: Sendable {

    static let shared = VisionService()

    /// Minimum confidence threshold for suggestions (40%)
    private let minimumConfidence: Float = 0.40

    /// Maximum number of suggestions to return
    private let maxSuggestions: Int = 10

    private init() {}

    // MARK: - Image Classification

    /// Classify a single image and return keyword suggestions
    func classifyImage(at url: URL) async throws -> [KeywordSuggestion] {
        guard let cgImage = loadCGImage(from: url) else {
            throw VisionError.cannotLoadImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: VisionError.classificationFailed(error.localizedDescription))
                    return
                }

                guard let observations = request.results as? [VNClassificationObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let suggestions = observations
                    .filter { $0.confidence >= self.minimumConfidence }
                    .prefix(self.maxSuggestions)
                    .map { KeywordSuggestion(
                        keyword: self.formatKeyword($0.identifier),
                        confidence: $0.confidence
                    )}

                continuation.resume(returning: Array(suggestions))
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: VisionError.classificationFailed(error.localizedDescription))
            }
        }
    }

    /// Classify multiple images and return union of suggestions
    /// - Parameters:
    ///   - urls: Array of image URLs to analyze
    ///   - progressHandler: Called after each image with progress 0.0-1.0
    /// - Returns: Combined suggestions sorted by confidence (highest first)
    func classifyImages(at urls: [URL], progressHandler: @Sendable @escaping (Double) -> Void) async throws -> [KeywordSuggestion] {
        var allSuggestions: [String: Float] = [:]  // keyword -> max confidence

        for (index, url) in urls.enumerated() {
            do {
                let suggestions = try await classifyImage(at: url)

                for suggestion in suggestions {
                    // Keep highest confidence for each keyword
                    let existing = allSuggestions[suggestion.keyword] ?? 0
                    allSuggestions[suggestion.keyword] = max(existing, suggestion.confidence)
                }
            } catch {
                // Skip images that fail, continue with others
                continue
            }

            progressHandler(Double(index + 1) / Double(urls.count))
        }

        return allSuggestions
            .map { KeywordSuggestion(keyword: $0.key, confidence: $0.value) }
            .sorted { $0.confidence > $1.confidence }
    }

    // MARK: - Private Helpers

    private func loadCGImage(from url: URL) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }
        return cgImage
    }

    /// Format Vision identifier to user-friendly keyword
    /// Vision returns identifiers like "outdoor_mountain" or "person"
    private func formatKeyword(_ identifier: String) -> String {
        identifier
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}

// MARK: - Vision Errors

enum VisionError: LocalizedError {
    case cannotLoadImage
    case classificationFailed(String)

    var errorDescription: String? {
        switch self {
        case .cannotLoadImage:
            return String(localized: "Cannot load image for analysis")
        case .classificationFailed(let reason):
            return String(localized: "Image classification failed: \(reason)")
        }
    }
}
