import Foundation
import CoreLocation

struct ExifMetadata: Equatable, Sendable {
    // Date/Time fields (primary editing targets)
    var dateTimeOriginal: Date?
    var dateTimeDigitized: Date?
    var dateTime: Date?

    // GPS fields
    var latitude: Double?
    var longitude: Double?
    var altitude: Double?

    // Keywords (IPTC)
    var keywords: [String] = []

    // Camera info (read-only display)
    var cameraMake: String?
    var cameraModel: String?
    var lensMake: String?
    var lensModel: String?
    var focalLength: Double?
    var fNumber: Double?
    var isoSpeed: Int?
    var exposureTime: Double?
    var flash: Bool?
    var software: String?
    var artist: String?
    var copyright: String?

    // Image dimensions
    var pixelWidth: Int?
    var pixelHeight: Int?
    var orientation: Int?

    // Raw dictionary for inspector
    var allProperties: [String: Any]?

    var coordinate: CLLocationCoordinate2D? {
        get {
            guard let lat = latitude, let lon = longitude else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        set {
            latitude = newValue?.latitude
            longitude = newValue?.longitude
        }
    }

    var formattedExposure: String? {
        guard let exposure = exposureTime else { return nil }
        if exposure >= 1 {
            return String(format: "%.1fs", exposure)
        } else {
            let denominator = Int(round(1.0 / exposure))
            return "1/\(denominator)s"
        }
    }

    var formattedFocalLength: String? {
        guard let focal = focalLength else { return nil }
        return String(format: "%.0fmm", focal)
    }

    var formattedAperture: String? {
        guard let f = fNumber else { return nil }
        return String(format: "f/%.1f", f)
    }

    var formattedISO: String? {
        guard let iso = isoSpeed else { return nil }
        return "ISO \(iso)"
    }

    var dimensionsString: String? {
        guard let w = pixelWidth, let h = pixelHeight else { return nil }
        return "\(w) × \(h)"
    }

    static func == (lhs: ExifMetadata, rhs: ExifMetadata) -> Bool {
        lhs.dateTimeOriginal == rhs.dateTimeOriginal &&
        lhs.dateTimeDigitized == rhs.dateTimeDigitized &&
        lhs.latitude == rhs.latitude &&
        lhs.longitude == rhs.longitude &&
        lhs.altitude == rhs.altitude &&
        lhs.keywords == rhs.keywords
    }
}
