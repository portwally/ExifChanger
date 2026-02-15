import SwiftUI
import UniformTypeIdentifiers

struct MainView: View {
    @State private var viewModel = PhotoLibraryViewModel()
    @State private var showInspector = false
    @State private var inspectedPhoto: PhotoItem?
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            HSplitView {
                // Left side: Photos
                photoPanel
                    .frame(minWidth: 300)

                // Right side: Editors
                if viewModel.hasPhotos {
                    editorPanel
                        .frame(minWidth: 380, idealWidth: 420)
                }
            }
        }
        .frame(minWidth: 760, minHeight: 500)
        .sheet(item: $inspectedPhoto) { photo in
            MetadataInspectorView(photo: photo)
        }
        .alert(String(localized: "Error"), isPresented: $viewModel.showError) {
            if viewModel.needsWriteAccess {
                Button(String(localized: "Open Photos...")) {
                    Task {
                        let urls = await viewModel.showOpenPanel()
                        viewModel.addPhotos(from: urls)
                    }
                }
                Button(String(localized: "Cancel"), role: .cancel) {}
            } else {
                Button(String(localized: "OK"), role: .cancel) {}
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .overlay {
            if viewModel.isProcessing {
                processingOverlay
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openPhotos)) { _ in
            Task {
                let urls = await viewModel.showOpenPanel()
                viewModel.addPhotos(from: urls)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showHelp)) { _ in
            openWindow(id: "help")
        }
    }

    // MARK: - Photo Panel

    private var photoPanel: some View {
        VStack(spacing: 0) {
            Group {
                if viewModel.hasPhotos {
                    PhotoGridView(viewModel: viewModel) { photo in
                        inspectedPhoto = photo
                    }
                } else {
                    PhotoDropZone { urls in
                        viewModel.addPhotos(from: urls)
                    } onChooseFiles: {
                        Task {
                            let urls = await viewModel.showOpenPanel()
                            viewModel.addPhotos(from: urls)
                        }
                    }
                }
            }

            // Bottom toolbar
            if viewModel.hasPhotos {
                Divider()
                photoToolbar
            }
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
            return true
        }
    }

    private var photoToolbar: some View {
        HStack {
            Button(String(localized: "Select All")) {
                viewModel.selectAll()
            }
            .disabled(viewModel.photos.isEmpty)

            Button(String(localized: "Deselect")) {
                viewModel.deselectAll()
            }
            .disabled(!viewModel.hasSelection)

            Spacer()

            Text("\(viewModel.selectedPhotoIDs.count) / \(viewModel.photos.count)")
                .foregroundStyle(.secondary)
                .font(.caption)

            Spacer()

            Button(String(localized: "Remove")) {
                viewModel.removeSelectedPhotos()
            }
            .disabled(!viewModel.hasSelection)

            Button(String(localized: "Remove All")) {
                viewModel.clearAllPhotos()
            }
            .disabled(viewModel.photos.isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.bar)
    }

    // MARK: - Editor Panel

    private var editorPanel: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Selection info
                    selectionHeader

                    if viewModel.hasSelection {
                        // Date/Time Editor
                        DateTimeEditorView(viewModel: viewModel)

                        Divider()

                        // Keywords Editor
                        KeywordSelectorView(viewModel: viewModel)

                        Divider()

                        // Location Editor
                        LocationPickerView(viewModel: viewModel)
                    } else {
                        Text("Select photos to edit")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 40)
                    }

                    Spacer()
                }
                .padding()
            }

            // Bottom action bar
            Divider()
            actionToolbar
        }
        .background(Color(.windowBackgroundColor))
    }

    private var actionToolbar: some View {
        HStack {
            Toggle(String(localized: "Sync file dates with EXIF"), isOn: $viewModel.syncFileDates)

            Spacer()

            Button(String(localized: "Reset Changes")) {
                viewModel.resetSelectedChanges()
            }
            .disabled(!viewModel.hasChanges)

            Button(String(localized: "Apply Changes")) {
                Task {
                    await viewModel.saveChanges()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.hasChanges)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private var selectionHeader: some View {
        HStack {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.title2)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading) {
                Text("\(viewModel.selectedPhotoIDs.count) photo(s) selected")
                    .font(.headline)

                if viewModel.hasChanges {
                    Text("\(viewModel.photosWithChanges.count) with pending changes")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    // MARK: - Processing Overlay

    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)

            VStack(spacing: 16) {
                ProgressView(value: viewModel.processingProgress)
                    .progressViewStyle(.linear)
                    .frame(width: 200)

                Text("Saving changes...")
                    .foregroundStyle(.white)
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .ignoresSafeArea()
    }

    // MARK: - Drop Handling

    private func handleDrop(providers: [NSItemProvider]) {
        Task {
            var urls: [URL] = []
            for provider in providers {
                if let url = try? await provider.loadItem(forTypeIdentifier: "public.file-url") as? URL {
                    urls.append(url)
                } else if let data = try? await provider.loadItem(forTypeIdentifier: "public.file-url") as? Data,
                          let urlString = String(data: data, encoding: .utf8),
                          let url = URL(string: urlString) {
                    urls.append(url)
                }
            }
            viewModel.addPhotos(from: urls)
        }
    }
}

#Preview {
    MainView()
}
