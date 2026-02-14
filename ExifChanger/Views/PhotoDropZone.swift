import SwiftUI
import UniformTypeIdentifiers

struct PhotoDropZone: View {
    let onDrop: ([URL]) -> Void
    let onChooseFiles: () -> Void

    @State private var isTargeted = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    isTargeted ? Color.accentColor : Color.secondary.opacity(0.4),
                    style: StrokeStyle(lineWidth: 3, dash: [12, 6])
                )
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isTargeted ? Color.accentColor.opacity(0.1) : Color.clear)
                )

            VStack(spacing: 20) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 56))
                    .foregroundStyle(isTargeted ? Color.accentColor : .secondary)

                VStack(spacing: 8) {
                    Text("Drop photos here")
                        .font(.title2)
                        .fontWeight(.medium)

                    Text("JPEG, HEIC, PNG, TIFF")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text("or")
                    .foregroundStyle(.secondary)

                Button(action: onChooseFiles) {
                    Label(String(localized: "Choose Files..."), systemImage: "folder")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(40)
        }
        .padding(20)
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
            return true
        }
    }

    private func handleDrop(providers: [NSItemProvider]) {
        Task {
            var urls: [URL] = []
            for provider in providers {
                if let url = try? await provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) as? URL {
                    urls.append(url)
                } else if let data = try? await provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) as? Data,
                          let urlString = String(data: data, encoding: .utf8),
                          let url = URL(string: urlString) {
                    urls.append(url)
                }
            }

            await MainActor.run {
                onDrop(urls)
            }
        }
    }
}

#Preview {
    PhotoDropZone { urls in
        print("Dropped: \(urls)")
    } onChooseFiles: {
        print("Choose files")
    }
    .frame(width: 400, height: 300)
}
