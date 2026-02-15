import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "camera.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.orange)
                Text("ExifEasy")
                    .font(.title)
                    .fontWeight(.semibold)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Getting Started
                    HelpSection(title: String(localized: "Getting Started"), icon: "photo.on.rectangle") {
                        HelpItem(
                            title: String(localized: "Add Photos"),
                            description: String(localized: "Drag and drop photos into the app, or use File → Open Photos (⌘O)")
                        )
                        HelpItem(
                            title: String(localized: "Select Photos"),
                            description: String(localized: "Click on photos to select them. Use Select All to select everything.")
                        )
                        HelpItem(
                            title: String(localized: "Supported Formats"),
                            description: String(localized: "JPEG, HEIC, PNG, and TIFF files are supported.")
                        )
                    }

                    // Date & Time
                    HelpSection(title: String(localized: "Date & Time"), icon: "calendar.badge.clock") {
                        HelpItem(
                            title: String(localized: "Change Date"),
                            description: String(localized: "Select photos, pick a new date/time, then click 'Apply to Selected'.")
                        )
                        HelpItem(
                            title: String(localized: "Use Original"),
                            description: String(localized: "Loads the original date from the first selected photo.")
                        )
                        HelpItem(
                            title: String(localized: "Sync File Dates"),
                            description: String(localized: "When enabled, the file's creation and modification dates will match the EXIF date.")
                        )
                    }

                    // Keywords
                    HelpSection(title: String(localized: "Keywords"), icon: "tag") {
                        HelpItem(
                            title: String(localized: "Add Keywords"),
                            description: String(localized: "Click on predefined keywords or type custom ones. Keywords are stored in IPTC metadata.")
                        )
                        HelpItem(
                            title: String(localized: "Compatibility"),
                            description: String(localized: "Keywords work with Lightroom, Capture One, and other professional photo software.")
                        )
                    }

                    // Location
                    HelpSection(title: String(localized: "Location"), icon: "mappin.and.ellipse") {
                        HelpItem(
                            title: String(localized: "View Locations"),
                            description: String(localized: "Select photos to see their GPS locations on the map (blue markers).")
                        )
                        HelpItem(
                            title: String(localized: "Set Location"),
                            description: String(localized: "Click on the map, search for a place, or use 'My Location' to set GPS coordinates.")
                        )
                        HelpItem(
                            title: String(localized: "Apply Location"),
                            description: String(localized: "The red marker shows the new location. Click 'Apply to Selected' to save it.")
                        )
                    }

                    // Inspector
                    HelpSection(title: String(localized: "Metadata Inspector"), icon: "info.circle") {
                        HelpItem(
                            title: String(localized: "Open Inspector"),
                            description: String(localized: "Click the (i) button on any photo to view all its metadata.")
                        )
                        HelpItem(
                            title: String(localized: "Tabs"),
                            description: String(localized: "Image, EXIF, TIFF, GPS, IPTC tabs show different metadata categories. Map tab shows the photo location.")
                        )
                    }

                    // Saving
                    HelpSection(title: String(localized: "Saving Changes"), icon: "square.and.arrow.down") {
                        HelpItem(
                            title: String(localized: "Pending Changes"),
                            description: String(localized: "Orange dots on thumbnails indicate unsaved changes.")
                        )
                        HelpItem(
                            title: String(localized: "Apply Changes"),
                            description: String(localized: "Click 'Apply Changes' to write all pending changes to the files.")
                        )
                        HelpItem(
                            title: String(localized: "Reset Changes"),
                            description: String(localized: "Discard pending changes and revert to the original metadata.")
                        )
                    }

                    // Tips
                    HelpSection(title: String(localized: "Tips"), icon: "lightbulb") {
                        HelpItem(
                            title: String(localized: "Batch Editing"),
                            description: String(localized: "Select multiple photos to apply the same date, location, or keywords to all of them at once.")
                        )
                        HelpItem(
                            title: String(localized: "File Permissions"),
                            description: String(localized: "If you get permission errors, use File → Open Photos instead of drag and drop.")
                        )
                    }
                }
                .padding()
            }

            Divider()

            // Footer
            HStack {
                Text("ExifEasy v1.0")
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
        .frame(width: 500, height: 550)
    }
}

struct HelpSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 8) {
                content
            }
            .padding(.leading, 28)
        }
    }
}

struct HelpItem: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    HelpView()
}
