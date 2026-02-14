import SwiftUI

struct PhotoGridView: View {
    @Bindable var viewModel: PhotoLibraryViewModel
    let onInspect: (PhotoItem) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 120, maximum: 150), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.photos) { photo in
                    PhotoThumbnailView(
                        photo: photo,
                        isSelected: viewModel.selectedPhotoIDs.contains(photo.id),
                        onInspect: { onInspect(photo) }
                    )
                    .onTapGesture {
                        viewModel.toggleSelection(for: photo)
                    }
                    .contextMenu {
                        Button(String(localized: "Inspect Metadata")) {
                            onInspect(photo)
                        }

                        Divider()

                        Button(String(localized: "Select")) {
                            viewModel.selectedPhotoIDs.insert(photo.id)
                        }

                        Button(String(localized: "Deselect")) {
                            viewModel.selectedPhotoIDs.remove(photo.id)
                        }

                        Divider()

                        Button(String(localized: "Remove"), role: .destructive) {
                            viewModel.photos.removeAll { $0.id == photo.id }
                            viewModel.selectedPhotoIDs.remove(photo.id)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.textBackgroundColor).opacity(0.5))
    }
}

struct PhotoThumbnailView: View {
    @ObservedObject var photo: PhotoItem
    let isSelected: Bool
    let onInspect: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                if let thumbnail = photo.thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 100)
                        .clipped()
                } else if photo.isLoading {
                    ProgressView()
                        .frame(width: 120, height: 100)
                } else {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                        .frame(width: 120, height: 100)
                }

                // Top-right indicators
                VStack {
                    HStack {
                        Spacer()

                        // Change indicator
                        if photo.hasChanges {
                            Circle()
                                .fill(.orange)
                                .frame(width: 10, height: 10)
                        }

                        // Info button
                        Button {
                            onInspect()
                        } label: {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.white, .black.opacity(0.5))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(4)
                    Spacer()
                }

                // Selection indicator
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor, lineWidth: 3)

                    VStack {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.white, Color.accentColor)
                                .padding(4)
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }
            .frame(width: 120, height: 100)
            .background(Color(.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(photo.filename)
                .font(.caption2)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(width: 120)
        }
        .opacity(photo.error != nil ? 0.5 : 1)
    }
}

#Preview("Grid") {
    let vm = PhotoLibraryViewModel()
    return PhotoGridView(viewModel: vm) { _ in }
        .frame(width: 400, height: 300)
}

#Preview("Thumbnail") {
    let photo = PhotoItem(url: URL(fileURLWithPath: "/test.jpg"))
    return PhotoThumbnailView(photo: photo, isSelected: true, onInspect: {})
        .padding()
}
