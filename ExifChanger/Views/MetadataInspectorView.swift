import SwiftUI
import MapKit
import CoreLocation

enum InspectorTab: String, CaseIterable {
    case image = "Image"
    case exif = "Exif"
    case tiff = "TIFF"
    case gps = "GPS"
    case iptc = "IPTC"
    case map = "Map"
}

struct MetadataInspectorView: View {
    let photo: PhotoItem
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: InspectorTab = .image

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            HStack(spacing: 0) {
                ForEach(InspectorTab.allCases, id: \.self) { tab in
                    TabButton(
                        title: tab.rawValue,
                        isSelected: selectedTab == tab
                    ) {
                        selectedTab = tab
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)

            Divider()
                .padding(.top, 8)

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    switch selectedTab {
                    case .image:
                        ImageTabContent(photo: photo)
                    case .exif:
                        ExifTabContent(metadata: photo.originalMetadata)
                    case .tiff:
                        TiffTabContent(metadata: photo.originalMetadata)
                    case .gps:
                        GpsTabContent(metadata: photo.originalMetadata)
                    case .iptc:
                        IptcTabContent(metadata: photo.originalMetadata)
                    case .map:
                        EmptyView() // Map handled separately
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .opacity(selectedTab == .map ? 0 : 1)
            .overlay {
                if selectedTab == .map {
                    MapTabContent(metadata: photo.originalMetadata)
                }
            }

            Divider()

            // Footer
            HStack {
                Text(photo.filename)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button(String(localized: "Close")) {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            .padding()
        }
        .frame(width: 600, height: 450)
    }
}

// MARK: - Tab Button

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(isSelected ? Color.orange : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Image Tab

struct ImageTabContent: View {
    let photo: PhotoItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let metadata = photo.originalMetadata {
                if let dims = metadata.dimensionsString {
                    InfoRow(label: "Size:", value: dims)
                }
                InfoRow(label: "File Format:", value: photo.fileExtension.uppercased())
                if let size = FileSystemService.shared.formattedFileSize(for: photo.url) {
                    InfoRow(label: "File Size:", value: size)
                }
                if let orientation = metadata.orientation {
                    InfoRow(label: "Orientation:", value: "\(orientation)")
                }
            } else {
                Text("No image data available")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Exif Tab

struct ExifTabContent: View {
    let metadata: ExifMetadata?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Basic Exif data:")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)

            if let metadata = metadata {
                if let date = metadata.dateTimeOriginal {
                    InfoRow(label: "Date/Time Original:", value: formatDate(date))
                }
                if let date = metadata.dateTimeDigitized {
                    InfoRow(label: "Date/Time Digitized:", value: formatDate(date))
                }
                if let aperture = metadata.formattedAperture {
                    InfoRow(label: "Aperture:", value: aperture)
                }
                if let shutter = metadata.formattedExposure {
                    InfoRow(label: "Exposure Time:", value: shutter)
                }
                if let iso = metadata.formattedISO {
                    InfoRow(label: "ISO:", value: iso)
                }
                if let focal = metadata.formattedFocalLength {
                    InfoRow(label: "Focal Length:", value: focal)
                }
                if let flash = metadata.flash {
                    InfoRow(label: "Flash:", value: flash ? "Yes" : "No")
                }
                if let lens = metadata.lensModel {
                    InfoRow(label: "Lens Model:", value: lens)
                }
                if let lensMake = metadata.lensMake {
                    InfoRow(label: "Lens Make:", value: lensMake)
                }

                // Raw EXIF dict if available
                if let props = metadata.allProperties,
                   let exifDict = props["{Exif}"] as? [String: Any] {
                    Divider().padding(.vertical, 8)
                    Text("-- Raw Exif IFD --")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(exifDict.keys.sorted(), id: \.self) { key in
                        InfoRow(label: "\(key):", value: "\(exifDict[key] ?? "")")
                    }
                }
            } else {
                Text("No EXIF data available")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return formatter.string(from: date)
    }
}

// MARK: - TIFF Tab

struct TiffTabContent: View {
    let metadata: ExifMetadata?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("TIFF metadata:")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)

            if let metadata = metadata {
                if let make = metadata.cameraMake {
                    InfoRow(label: "Make:", value: make)
                }
                if let model = metadata.cameraModel {
                    InfoRow(label: "Model:", value: model)
                }
                if let software = metadata.software {
                    InfoRow(label: "Software:", value: software)
                }
                if let date = metadata.dateTime {
                    InfoRow(label: "DateTime:", value: formatDate(date))
                }
                if let artist = metadata.artist {
                    InfoRow(label: "Artist:", value: artist)
                }
                if let copyright = metadata.copyright {
                    InfoRow(label: "Copyright:", value: copyright)
                }
                if let orientation = metadata.orientation {
                    InfoRow(label: "Orientation:", value: "\(orientation)")
                }

                // Raw TIFF dict if available
                if let props = metadata.allProperties,
                   let tiffDict = props["{TIFF}"] as? [String: Any] {
                    Divider().padding(.vertical, 8)
                    Text("-- Raw TIFF IFD --")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(tiffDict.keys.sorted(), id: \.self) { key in
                        InfoRow(label: "\(key):", value: "\(tiffDict[key] ?? "")")
                    }
                }
            } else {
                Text("No TIFF data available")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return formatter.string(from: date)
    }
}

// MARK: - GPS Tab

struct GpsTabContent: View {
    let metadata: ExifMetadata?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("GPS data:")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)

            if let metadata = metadata, let coord = metadata.coordinate {
                InfoRow(label: "Latitude:", value: formatCoordinate(coord.latitude, isLatitude: true))
                InfoRow(label: "Longitude:", value: formatCoordinate(coord.longitude, isLatitude: false))
                if let alt = metadata.altitude {
                    InfoRow(label: "Altitude:", value: String(format: "%.1f m", alt))
                }

                // Raw GPS dict if available
                if let props = metadata.allProperties,
                   let gpsDict = props["{GPS}"] as? [String: Any] {
                    Divider().padding(.vertical, 8)
                    Text("-- Raw GPS IFD --")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(gpsDict.keys.sorted(), id: \.self) { key in
                        InfoRow(label: "\(key):", value: "\(gpsDict[key] ?? "")")
                    }
                }
            } else {
                Text("No GPS data available")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func formatCoordinate(_ value: Double, isLatitude: Bool) -> String {
        let direction = isLatitude ? (value >= 0 ? "N" : "S") : (value >= 0 ? "E" : "W")
        let absValue = abs(value)
        let degrees = Int(absValue)
        let minutes = Int((absValue - Double(degrees)) * 60)
        let seconds = (absValue - Double(degrees) - Double(minutes) / 60) * 3600
        return String(format: "%d°%d'%.2f\" %@  (%.6f)", degrees, minutes, seconds, direction, value)
    }
}

// MARK: - IPTC Tab

struct IptcTabContent: View {
    let metadata: ExifMetadata?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("IPTC metadata:")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)

            if let metadata = metadata {
                if !metadata.keywords.isEmpty {
                    InfoRow(label: "Keywords:", value: metadata.keywords.joined(separator: ", "))
                }

                // Raw IPTC dict if available
                if let props = metadata.allProperties,
                   let iptcDict = props["{IPTC}"] as? [String: Any] {
                    Divider().padding(.vertical, 8)
                    Text("-- Raw IPTC data --")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(iptcDict.keys.sorted(), id: \.self) { key in
                        InfoRow(label: "\(key):", value: "\(iptcDict[key] ?? "")")
                    }
                }

                if metadata.keywords.isEmpty {
                    Text("No IPTC keywords")
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("No IPTC data available")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Map Tab

struct MapTabContent: View {
    let metadata: ExifMetadata?
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        Group {
            if let coord = metadata?.coordinate {
                Map(position: $cameraPosition) {
                    Marker("Photo Location", coordinate: coord)
                        .tint(.red)
                }
                .mapStyle(.standard)
                .onAppear {
                    cameraPosition = .region(MKCoordinateRegion(
                        center: coord,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    ))
                }
            } else {
                VStack {
                    Image(systemName: "map")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No GPS data available")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 200, alignment: .trailing)
            Text(value)
                .textSelection(.enabled)
            Spacer()
        }
        .font(.system(size: 12, design: .monospaced))
    }
}

#Preview {
    let photo = PhotoItem(url: URL(fileURLWithPath: "/test.jpg"))
    return MetadataInspectorView(photo: photo)
}
