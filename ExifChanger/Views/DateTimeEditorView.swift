import SwiftUI

struct DateTimeEditorView: View {
    @Bindable var viewModel: PhotoLibraryViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(String(localized: "Date & Time"), systemImage: "calendar.badge.clock")
                .font(.headline)

            // Show original date from first selected photo
            if let firstPhoto = viewModel.selectedPhotos.first,
               let originalDate = firstPhoto.originalMetadata?.dateTimeOriginal {
                HStack {
                    Text("Original:")
                        .foregroundStyle(.secondary)
                    Text(originalDate, format: .dateTime)
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }

            // Date picker
            VStack(alignment: .leading, spacing: 8) {
                Text("New Date & Time:")
                    .font(.subheadline)

                DatePicker(
                    "",
                    selection: $viewModel.editingDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.field)
                .labelsHidden()
            }

            // Quick actions
            HStack {
                Button(String(localized: "Now")) {
                    viewModel.editingDate = Date()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button(String(localized: "Use Original")) {
                    if let firstPhoto = viewModel.selectedPhotos.first,
                       let originalDate = firstPhoto.originalMetadata?.dateTimeOriginal {
                        viewModel.editingDate = originalDate
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(viewModel.selectedPhotos.first?.originalMetadata?.dateTimeOriginal == nil)

                Spacer()

                Button(String(localized: "Apply to Selected")) {
                    viewModel.applyDateToSelected()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(!viewModel.hasSelection)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onAppear {
            // Initialize with first selected photo's date
            if let firstPhoto = viewModel.selectedPhotos.first,
               let originalDate = firstPhoto.originalMetadata?.dateTimeOriginal {
                viewModel.editingDate = originalDate
            }
        }
    }
}

#Preview {
    let vm = PhotoLibraryViewModel()
    return DateTimeEditorView(viewModel: vm)
        .frame(width: 350)
        .padding()
}
