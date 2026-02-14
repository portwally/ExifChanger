import Foundation
import AppKit
internal import Combine
import UniformTypeIdentifiers

@MainActor
class PhotoItem: Identifiable, ObservableObject, Hashable {
    let id: UUID
    let url: URL

    @Published var thumbnail: NSImage?
    @Published var isLoading: Bool = true
    @Published var error: String?
    @Published private(set) var hasChanges: Bool = false

    private var _originalMetadata: ExifMetadata? {
        didSet {
            updateHasChanges()
        }
    }

    var originalMetadata: ExifMetadata? {
        get { _originalMetadata }
        set {
            objectWillChange.send()
            _originalMetadata = newValue
        }
    }

    private var _pendingMetadata: ExifMetadata? {
        didSet {
            updateHasChanges()
        }
    }

    var pendingMetadata: ExifMetadata? {
        get { _pendingMetadata }
        set {
            objectWillChange.send()
            _pendingMetadata = newValue
        }
    }

    var filename: String { url.lastPathComponent }

    var fileExtension: String { url.pathExtension.lowercased() }

    private func updateHasChanges() {
        // If no pending metadata, no changes
        guard let pending = _pendingMetadata else {
            hasChanges = false
            return
        }
        // If no original metadata but we have pending, that's a change
        guard let original = _originalMetadata else {
            hasChanges = true
            return
        }
        // Compare pending vs original
        hasChanges = pending != original
    }

    var imageFormat: ImageFormat? {
        ImageFormat.from(extension: fileExtension)
    }

    var supportsExif: Bool {
        imageFormat?.supportsExif ?? false
    }

    init(url: URL) {
        self.id = UUID()
        self.url = url
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    nonisolated static func == (lhs: PhotoItem, rhs: PhotoItem) -> Bool {
        lhs.id == rhs.id
    }

    func resetChanges() {
        pendingMetadata = originalMetadata
    }
}

enum ImageFormat: String, CaseIterable, Sendable {
    case jpeg
    case heic
    case heif
    case png
    case tiff
    case tif

    var supportsExif: Bool {
        switch self {
        case .jpeg, .heic, .heif, .tiff, .tif:
            return true
        case .png:
            return false
        }
    }

    var utType: UTType {
        switch self {
        case .jpeg: return .jpeg
        case .heic, .heif: return .heic
        case .png: return .png
        case .tiff, .tif: return .tiff
        }
    }

    var uti: String {
        utType.identifier
    }

    static func from(extension ext: String) -> ImageFormat? {
        let lower = ext.lowercased()
        // Handle common aliases
        if lower == "jpg" { return .jpeg }
        return ImageFormat.allCases.first { $0.rawValue == lower }
    }

    static var supportedExtensions: [String] {
        var extensions = allCases.map { $0.rawValue }
        extensions.append("jpg") // Common alias for jpeg
        return extensions
    }

    static var supportedUTTypes: [UTType] {
        [.jpeg, .heic, .png, .tiff]
    }
}
