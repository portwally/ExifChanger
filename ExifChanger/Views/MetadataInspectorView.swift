import SwiftUI
import CoreLocation

struct MetadataInspectorView: View {
    let photo: PhotoItem
    @Environment(\.dismiss) private var dismiss
    @State private var showRawKeys = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(photo.filename)
                        .font(.headline)
                    if let size = FileSystemService.shared.formattedFileSize(for: photo.url) {
                        Text(size)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Toggle(String(localized: "Raw Keys"), isOn: $showRawKeys)
                    .toggleStyle(.switch)
                    .controlSize(.small)

                Button(String(localized: "Close")) {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            .padding()
            .background(.bar)

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let metadata = photo.originalMetadata {
                        // Image Info
                        MetadataSection(title: String(localized: "Image")) {
                            if let dims = metadata.dimensionsString {
                                MetadataRow(label: String(localized: "Dimensions"), value: dims)
                            }
                            if let orientation = metadata.orientation {
                                MetadataRow(label: String(localized: "Orientation"), value: "\(orientation)")
                            }
                            MetadataRow(label: String(localized: "Format"), value: photo.fileExtension.uppercased())
                        }

                        // Date/Time
                        MetadataSection(title: String(localized: "Date & Time")) {
                            if let date = metadata.dateTimeOriginal {
                                MetadataRow(label: String(localized: "Date Taken"), value: date.formatted())
                            }
                            if let date = metadata.dateTimeDigitized {
                                MetadataRow(label: String(localized: "Date Digitized"), value: date.formatted())
                            }
                            if let date = metadata.dateTime {
                                MetadataRow(label: String(localized: "Date Modified"), value: date.formatted())
                            }
                        }

                        // Camera
                        MetadataSection(title: String(localized: "Camera")) {
                            if let make = metadata.cameraMake {
                                MetadataRow(label: String(localized: "Make"), value: make)
                            }
                            if let model = metadata.cameraModel {
                                MetadataRow(label: String(localized: "Model"), value: model)
                            }
                            if let lens = metadata.lensModel {
                                MetadataRow(label: String(localized: "Lens"), value: lens)
                            }
                            if let software = metadata.software {
                                MetadataRow(label: String(localized: "Software"), value: software)
                            }
                        }

                        // Exposure
                        MetadataSection(title: String(localized: "Exposure")) {
                            if let aperture = metadata.formattedAperture {
                                MetadataRow(label: String(localized: "Aperture"), value: aperture)
                            }
                            if let shutter = metadata.formattedExposure {
                                MetadataRow(label: String(localized: "Shutter Speed"), value: shutter)
                            }
                            if let iso = metadata.formattedISO {
                                MetadataRow(label: "ISO", value: iso)
                            }
                            if let focal = metadata.formattedFocalLength {
                                MetadataRow(label: String(localized: "Focal Length"), value: focal)
                            }
                            if let flash = metadata.flash {
                                MetadataRow(label: String(localized: "Flash"), value: flash ? String(localized: "Yes") : String(localized: "No"))
                            }
                        }

                        // Location
                        if let coord = metadata.coordinate {
                            MetadataSection(title: String(localized: "Location")) {
                                MetadataRow(label: String(localized: "Latitude"), value: String(format: "%.6f", coord.latitude))
                                MetadataRow(label: String(localized: "Longitude"), value: String(format: "%.6f", coord.longitude))
                                if let alt = metadata.altitude {
                                    MetadataRow(label: String(localized: "Altitude"), value: String(format: "%.1f m", alt))
                                }
                            }
                        }

                        // Keywords
                        if !metadata.keywords.isEmpty {
                            MetadataSection(title: String(localized: "Keywords")) {
                                Text(metadata.keywords.joined(separator: ", "))
                                    .font(.body)
                            }
                        }

                        // Copyright
                        if metadata.artist != nil || metadata.copyright != nil {
                            MetadataSection(title: String(localized: "Copyright")) {
                                if let artist = metadata.artist {
                                    MetadataRow(label: String(localized: "Artist"), value: artist)
                                }
                                if let copyright = metadata.copyright {
                                    MetadataRow(label: String(localized: "Copyright"), value: copyright)
                                }
                            }
                        }

                        // Raw properties
                        if showRawKeys, let props = metadata.allProperties {
                            MetadataSection(title: String(localized: "Raw Metadata")) {
                                RawMetadataView(properties: props)
                            }
                        }
                    } else {
                        Text("No metadata available")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 40)
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 450, minHeight: 500)
    }
}

struct MetadataSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                content
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.controlBackgroundColor).opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct MetadataRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 120, alignment: .leading)
            Text(value)
                .textSelection(.enabled)
            Spacer()
        }
        .font(.callout)
    }
}

struct RawMetadataView: View {
    let properties: [String: Any]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(sortedKeys, id: \.self) { key in
                VStack(alignment: .leading, spacing: 2) {
                    Text(key)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let dict = properties[key] as? [String: Any] {
                        ForEach(dict.keys.sorted(), id: \.self) { subKey in
                            HStack(alignment: .top) {
                                Text("  \(subKey):")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text("\(String(describing: dict[subKey]!))")
                                    .font(.caption2)
                                    .textSelection(.enabled)
                            }
                        }
                    } else {
                        Text("\(String(describing: properties[key]!))")
                            .font(.caption2)
                            .textSelection(.enabled)
                    }
                }
            }
        }
    }

    private var sortedKeys: [String] {
        properties.keys.sorted()
    }
}

#Preview {
    let photo = PhotoItem(url: URL(fileURLWithPath: "/test.jpg"))
    return MetadataInspectorView(photo: photo)
}
