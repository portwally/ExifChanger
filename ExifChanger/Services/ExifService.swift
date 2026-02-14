import Foundation
import ImageIO
import CoreLocation
import UniformTypeIdentifiers
import AppKit

final class ExifService: Sendable {

    static let shared = ExifService()

    private init() {}

    // MARK: - Read Metadata

    func readMetadata(from url: URL) throws -> ExifMetadata {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            throw ExifError.cannotOpenFile
        }

        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            throw ExifError.cannotReadMetadata
        }

        var metadata = ExifMetadata()
        metadata.allProperties = properties

        // Parse EXIF dictionary
        if let exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any] {
            metadata.dateTimeOriginal = parseExifDate(exif[kCGImagePropertyExifDateTimeOriginal as String] as? String)
            metadata.dateTimeDigitized = parseExifDate(exif[kCGImagePropertyExifDateTimeDigitized as String] as? String)
            metadata.fNumber = exif[kCGImagePropertyExifFNumber as String] as? Double
            metadata.isoSpeed = (exif[kCGImagePropertyExifISOSpeedRatings as String] as? [Int])?.first
            metadata.exposureTime = exif[kCGImagePropertyExifExposureTime as String] as? Double
            metadata.focalLength = exif[kCGImagePropertyExifFocalLength as String] as? Double
            metadata.flash = (exif[kCGImagePropertyExifFlash as String] as? Int).map { $0 != 0 }
            metadata.lensMake = exif[kCGImagePropertyExifLensMake as String] as? String
            metadata.lensModel = exif[kCGImagePropertyExifLensModel as String] as? String
        }

        // Parse TIFF dictionary
        if let tiff = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any] {
            metadata.dateTime = parseExifDate(tiff[kCGImagePropertyTIFFDateTime as String] as? String)
            metadata.cameraMake = tiff[kCGImagePropertyTIFFMake as String] as? String
            metadata.cameraModel = tiff[kCGImagePropertyTIFFModel as String] as? String
            metadata.software = tiff[kCGImagePropertyTIFFSoftware as String] as? String
            metadata.artist = tiff[kCGImagePropertyTIFFArtist as String] as? String
            metadata.copyright = tiff[kCGImagePropertyTIFFCopyright as String] as? String
            metadata.orientation = tiff[kCGImagePropertyTIFFOrientation as String] as? Int
        }

        // Parse GPS dictionary
        if let gps = properties[kCGImagePropertyGPSDictionary as String] as? [String: Any] {
            metadata.coordinate = parseGPSCoordinate(from: gps)
            metadata.altitude = gps[kCGImagePropertyGPSAltitude as String] as? Double
        }

        // Parse IPTC dictionary for keywords
        if let iptc = properties[kCGImagePropertyIPTCDictionary as String] as? [String: Any] {
            if let keywords = iptc[kCGImagePropertyIPTCKeywords as String] as? [String] {
                metadata.keywords = keywords
            }
        }

        // Parse basic image properties
        metadata.pixelWidth = properties[kCGImagePropertyPixelWidth as String] as? Int
        metadata.pixelHeight = properties[kCGImagePropertyPixelHeight as String] as? Int

        return metadata
    }

    // MARK: - Write Metadata

    func writeMetadata(to url: URL, metadata: ExifMetadata) throws {
        guard let uti = UTType(filenameExtension: url.pathExtension) else {
            throw ExifError.unsupportedFormat
        }

        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            throw ExifError.cannotOpenFile
        }

        guard let existingProperties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            throw ExifError.cannotReadMetadata
        }

        var updatedProperties = existingProperties

        // Update EXIF dictionary
        var exifDict = (existingProperties[kCGImagePropertyExifDictionary as String] as? [String: Any]) ?? [:]

        if let dateOriginal = metadata.dateTimeOriginal {
            exifDict[kCGImagePropertyExifDateTimeOriginal as String] = formatExifDate(dateOriginal)
        }
        if let dateDigitized = metadata.dateTimeDigitized {
            exifDict[kCGImagePropertyExifDateTimeDigitized as String] = formatExifDate(dateDigitized)
        }

        updatedProperties[kCGImagePropertyExifDictionary as String] = exifDict

        // Update TIFF dictionary
        var tiffDict = (existingProperties[kCGImagePropertyTIFFDictionary as String] as? [String: Any]) ?? [:]

        if let dateTime = metadata.dateTime ?? metadata.dateTimeOriginal {
            tiffDict[kCGImagePropertyTIFFDateTime as String] = formatExifDate(dateTime)
        }

        updatedProperties[kCGImagePropertyTIFFDictionary as String] = tiffDict

        // Update GPS dictionary
        if let coordinate = metadata.coordinate {
            var gpsDict: [String: Any] = [:]
            gpsDict[kCGImagePropertyGPSLatitude as String] = abs(coordinate.latitude)
            gpsDict[kCGImagePropertyGPSLatitudeRef as String] = coordinate.latitude >= 0 ? "N" : "S"
            gpsDict[kCGImagePropertyGPSLongitude as String] = abs(coordinate.longitude)
            gpsDict[kCGImagePropertyGPSLongitudeRef as String] = coordinate.longitude >= 0 ? "E" : "W"
            gpsDict[kCGImagePropertyGPSVersion as String] = "2.3.0.0"

            if let altitude = metadata.altitude {
                gpsDict[kCGImagePropertyGPSAltitude as String] = abs(altitude)
                gpsDict[kCGImagePropertyGPSAltitudeRef as String] = altitude >= 0 ? 0 : 1
            }

            updatedProperties[kCGImagePropertyGPSDictionary as String] = gpsDict
        } else {
            updatedProperties.removeValue(forKey: kCGImagePropertyGPSDictionary as String)
        }

        // Update IPTC dictionary for keywords
        var iptcDict = (existingProperties[kCGImagePropertyIPTCDictionary as String] as? [String: Any]) ?? [:]

        if !metadata.keywords.isEmpty {
            iptcDict[kCGImagePropertyIPTCKeywords as String] = metadata.keywords
        } else {
            iptcDict.removeValue(forKey: kCGImagePropertyIPTCKeywords as String)
        }

        updatedProperties[kCGImagePropertyIPTCDictionary as String] = iptcDict

        // Write to file
        try writeImageWithMetadata(source: source, to: url, properties: updatedProperties, type: uti.identifier as CFString)
    }

    // MARK: - Thumbnail Generation

    func generateThumbnail(for url: URL, maxSize: CGFloat = 150) -> NSImage? {
        let options: [CFString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: maxSize,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]

        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }

        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }

    // MARK: - Private Helpers

    private func writeImageWithMetadata(source: CGImageSource, to url: URL, properties: [String: Any], type: CFString) throws {
        // Write to NSMutableData first to avoid temp file permission issues
        let data = NSMutableData()

        guard let destination = CGImageDestinationCreateWithData(data as CFMutableData, type, 1, nil) else {
            throw ExifError.cannotCreateDestination
        }

        CGImageDestinationAddImageFromSource(destination, source, 0, properties as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw ExifError.writeFailed
        }

        // Write data directly to file
        do {
            try (data as Data).write(to: url, options: .atomic)
        } catch {
            throw ExifError.noWritePermission
        }
    }

    private func parseExifDate(_ string: String?) -> Date? {
        guard let string = string else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: string)
    }

    private func formatExifDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }

    private func parseGPSCoordinate(from gps: [String: Any]) -> CLLocationCoordinate2D? {
        guard let latitude = gps[kCGImagePropertyGPSLatitude as String] as? Double,
              let latitudeRef = gps[kCGImagePropertyGPSLatitudeRef as String] as? String,
              let longitude = gps[kCGImagePropertyGPSLongitude as String] as? Double,
              let longitudeRef = gps[kCGImagePropertyGPSLongitudeRef as String] as? String else {
            return nil
        }

        let lat = latitudeRef == "S" ? -latitude : latitude
        let lon = longitudeRef == "W" ? -longitude : longitude

        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

enum ExifError: LocalizedError {
    case cannotOpenFile
    case cannotReadMetadata
    case unsupportedFormat
    case cannotCreateDestination
    case writeFailed
    case noWritePermission

    var errorDescription: String? {
        switch self {
        case .cannotOpenFile:
            return String(localized: "Cannot open the image file")
        case .cannotReadMetadata:
            return String(localized: "Cannot read image metadata")
        case .unsupportedFormat:
            return String(localized: "Image format not supported")
        case .cannotCreateDestination:
            return String(localized: "Cannot create output file")
        case .writeFailed:
            return String(localized: "Failed to write changes")
        case .noWritePermission:
            return String(localized: "No permission to write. Please use File > Open to add photos instead of drag and drop.")
        }
    }
}
