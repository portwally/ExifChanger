import Foundation
import SwiftUI
import CoreLocation
import UniformTypeIdentifiers

@MainActor
@Observable
final class PhotoLibraryViewModel {

    var photos: [PhotoItem] = []
    var selectedPhotoIDs: Set<UUID> = []
    var isProcessing: Bool = false
    var processingProgress: Double = 0
    var errorMessage: String?
    var showError: Bool = false

    // Editing state
    var editingDate: Date = Date()
    var editingCoordinate: CLLocationCoordinate2D?
    var editingKeywords: Set<String> = []
    var syncFileDates: Bool = true

    // Manual refresh trigger for hasChanges
    private var changeCounter: Int = 0

    var selectedPhotos: [PhotoItem] {
        photos.filter { selectedPhotoIDs.contains($0.id) }
    }

    var hasPhotos: Bool {
        !photos.isEmpty
    }

    var hasSelection: Bool {
        !selectedPhotoIDs.isEmpty
    }

    var photosWithChanges: [PhotoItem] {
        // Access changeCounter to create dependency
        _ = changeCounter
        return photos.filter { $0.hasChanges }
    }

    var hasChanges: Bool {
        !photosWithChanges.isEmpty
    }

    private func notifyChanges() {
        changeCounter += 1
    }

    // MARK: - Photo Management

    func addPhotos(from urls: [URL]) {
        let validURLs = urls.filter { url in
            ImageFormat.supportedExtensions.contains(url.pathExtension.lowercased())
        }

        for url in validURLs {
            guard !photos.contains(where: { $0.url == url }) else { continue }

            let photo = PhotoItem(url: url)
            photos.append(photo)
            loadPhotoData(photo)
        }
    }

    func removeSelectedPhotos() {
        photos.removeAll { selectedPhotoIDs.contains($0.id) }
        selectedPhotoIDs.removeAll()
    }

    func clearAllPhotos() {
        photos.removeAll()
        selectedPhotoIDs.removeAll()
    }

    func selectAll() {
        selectedPhotoIDs = Set(photos.map { $0.id })
    }

    func deselectAll() {
        selectedPhotoIDs.removeAll()
    }

    func toggleSelection(for photo: PhotoItem) {
        if selectedPhotoIDs.contains(photo.id) {
            selectedPhotoIDs.remove(photo.id)
        } else {
            selectedPhotoIDs.insert(photo.id)
        }
    }

    // MARK: - Photo Loading

    private func loadPhotoData(_ photo: PhotoItem) {
        Task {
            photo.isLoading = true

            // Generate thumbnail
            let thumbnail = await Task.detached(priority: .userInitiated) {
                return ExifService.shared.generateThumbnail(for: photo.url)
            }.value
            if let thumbnail = thumbnail {
                photo.thumbnail = thumbnail
            }

            // Read metadata
            do {
                let metadata = try await Task.detached(priority: .userInitiated) {
                    try ExifService.shared.readMetadata(from: photo.url)
                }.value
                photo.originalMetadata = metadata
                photo.pendingMetadata = metadata
            } catch {
                photo.error = error.localizedDescription
            }

            photo.isLoading = false
        }
    }

    // MARK: - Editing

    func applyDateToSelected() {
        for photo in selectedPhotos {
            var metadata = photo.pendingMetadata ?? ExifMetadata()
            metadata.dateTimeOriginal = editingDate
            metadata.dateTimeDigitized = editingDate
            metadata.dateTime = editingDate
            photo.pendingMetadata = metadata
        }
        notifyChanges()
    }

    func applyLocationToSelected() {
        for photo in selectedPhotos {
            var metadata = photo.pendingMetadata ?? ExifMetadata()
            metadata.coordinate = editingCoordinate
            photo.pendingMetadata = metadata
        }
        notifyChanges()
    }

    func removeLocationFromSelected() {
        for photo in selectedPhotos {
            var metadata = photo.pendingMetadata ?? ExifMetadata()
            metadata.coordinate = nil
            metadata.altitude = nil
            photo.pendingMetadata = metadata
        }
        notifyChanges()
    }

    func applyKeywordsToSelected() {
        for photo in selectedPhotos {
            var metadata = photo.pendingMetadata ?? ExifMetadata()
            metadata.keywords = Array(editingKeywords)
            photo.pendingMetadata = metadata
        }
        notifyChanges()
    }

    func resetSelectedChanges() {
        for photo in selectedPhotos {
            photo.resetChanges()
        }
        notifyChanges()
    }

    // MARK: - Save Changes

    var needsWriteAccess: Bool = false

    func saveChanges() async {
        let photosToSave = photosWithChanges
        guard !photosToSave.isEmpty else { return }

        isProcessing = true
        processingProgress = 0
        needsWriteAccess = false

        let total = Double(photosToSave.count)

        for (index, photo) in photosToSave.enumerated() {
            guard let metadata = photo.pendingMetadata else { continue }

            do {
                // Write EXIF changes
                try await Task.detached(priority: .userInitiated) {
                    try ExifService.shared.writeMetadata(to: photo.url, metadata: metadata)
                }.value

                // Sync file dates if enabled
                if syncFileDates, let dateOriginal = metadata.dateTimeOriginal {
                    try FileSystemService.shared.updateFileDates(
                        for: photo.url,
                        creationDate: dateOriginal,
                        modificationDate: dateOriginal
                    )
                }

                // Update original metadata to reflect saved changes
                photo.originalMetadata = metadata

            } catch let error as ExifError where error == .noWritePermission {
                needsWriteAccess = true
                errorMessage = String(localized: "Cannot write to files. Use 'File → Open Photos' to grant write access, then try saving again.")
                showError = true
                break
            } catch {
                errorMessage = "\(photo.filename): \(error.localizedDescription)"
                showError = true
            }

            processingProgress = Double(index + 1) / total
        }

        isProcessing = false
        processingProgress = 0
        notifyChanges()
    }

    /// Re-open files with write access using NSOpenPanel
    func requestWriteAccessForPhotos() async {
        let urls = photos.map { $0.url }
        guard !urls.isEmpty else { return }

        // Get unique parent directories
        let directories = Set(urls.map { $0.deletingLastPathComponent() })

        await MainActor.run {
            let panel = NSOpenPanel()
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.allowsMultipleSelection = true
            panel.message = String(localized: "Select the folder(s) containing your photos to grant write access")
            panel.prompt = String(localized: "Grant Access")
            panel.directoryURL = directories.first

            if panel.runModal() == .OK {
                // Access granted - the URLs now have write permission
            }
        }
    }

    // MARK: - File Picker

    func showOpenPanel() async -> [URL] {
        await MainActor.run {
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = true
            panel.canChooseFiles = true
            panel.canChooseDirectories = false
            panel.allowedContentTypes = ImageFormat.supportedUTTypes
            panel.message = String(localized: "Select photos to edit")
            panel.prompt = String(localized: "Open")

            guard panel.runModal() == .OK else { return [] }
            return panel.urls
        }
    }
}

// MARK: - Predefined Keywords

enum PhotoKeyword: String, CaseIterable, Identifiable {
    case concert = "Concert"
    case wedding = "Wedding"
    case portrait = "Portrait"
    case event = "Event"
    case landscape = "Landscape"
    case family = "Family"
    case corporate = "Corporate"
    case fashion = "Fashion"
    case product = "Product"
    case birthday = "Birthday"
    case baptism = "Baptism"
    case graduation = "Graduation"

    var id: String { rawValue }

    var localizedName: String {
        String(localized: LocalizedStringResource(stringLiteral: rawValue))
    }
}
