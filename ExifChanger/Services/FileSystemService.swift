import Foundation

final class FileSystemService: Sendable {

    static let shared = FileSystemService()

    private init() {}

    func updateFileDates(for url: URL, creationDate: Date?, modificationDate: Date?) throws {
        var attributes: [FileAttributeKey: Any] = [:]

        if let creation = creationDate {
            attributes[.creationDate] = creation
        }
        if let modification = modificationDate {
            attributes[.modificationDate] = modification
        }

        guard !attributes.isEmpty else { return }

        try FileManager.default.setAttributes(attributes, ofItemAtPath: url.path)
    }

    func readFileDates(for url: URL) throws -> (creation: Date?, modification: Date?) {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        return (
            creation: attributes[.creationDate] as? Date,
            modification: attributes[.modificationDate] as? Date
        )
    }

    func fileSize(for url: URL) -> Int64? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? Int64 else {
            return nil
        }
        return size
    }

    func formattedFileSize(for url: URL) -> String? {
        guard let size = fileSize(for: url) else { return nil }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}
