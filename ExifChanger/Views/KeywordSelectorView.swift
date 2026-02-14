import SwiftUI

struct KeywordSelectorView: View {
    @Bindable var viewModel: PhotoLibraryViewModel
    @State private var customKeyword: String = ""

    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 8)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(String(localized: "Keywords"), systemImage: "tag")
                .font(.headline)

            // Show existing keywords from first selected photo
            if let firstPhoto = viewModel.selectedPhotos.first,
               let keywords = firstPhoto.originalMetadata?.keywords,
               !keywords.isEmpty {
                HStack {
                    Text("Current:")
                        .foregroundStyle(.secondary)
                    Text(keywords.joined(separator: ", "))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .font(.caption)
            }

            // Predefined keywords grid
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(PhotoKeyword.allCases) { keyword in
                    KeywordChip(
                        title: keyword.localizedName,
                        isSelected: viewModel.editingKeywords.contains(keyword.rawValue)
                    ) {
                        toggleKeyword(keyword.rawValue)
                    }
                }
            }

            // Custom keyword input
            HStack {
                TextField(String(localized: "Custom keyword..."), text: $customKeyword)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        addCustomKeyword()
                    }

                Button(String(localized: "Add")) {
                    addCustomKeyword()
                }
                .disabled(customKeyword.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            // Selected keywords display
            if !viewModel.editingKeywords.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Selected keywords:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    FlowLayout(spacing: 4) {
                        ForEach(Array(viewModel.editingKeywords).sorted(), id: \.self) { keyword in
                            HStack(spacing: 4) {
                                Text(keyword)
                                    .font(.caption)
                                Button {
                                    viewModel.editingKeywords.remove(keyword)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption2)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.2))
                            .clipShape(Capsule())
                        }
                    }
                }
            }

            // Actions
            HStack {
                Button(String(localized: "Clear")) {
                    viewModel.editingKeywords.removeAll()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(viewModel.editingKeywords.isEmpty)

                Button(String(localized: "Load from Photo")) {
                    if let firstPhoto = viewModel.selectedPhotos.first,
                       let keywords = firstPhoto.originalMetadata?.keywords {
                        viewModel.editingKeywords = Set(keywords)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()

                Button(String(localized: "Apply to Selected")) {
                    viewModel.applyKeywordsToSelected()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(!viewModel.hasSelection)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func toggleKeyword(_ keyword: String) {
        if viewModel.editingKeywords.contains(keyword) {
            viewModel.editingKeywords.remove(keyword)
        } else {
            viewModel.editingKeywords.insert(keyword)
        }
    }

    private func addCustomKeyword() {
        let trimmed = customKeyword.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        viewModel.editingKeywords.insert(trimmed)
        customKeyword = ""
    }
}

struct KeywordChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.accentColor : Color(.controlBackgroundColor))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)

        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }

        let totalHeight = currentY + lineHeight
        let totalWidth = maxWidth

        return (CGSize(width: totalWidth, height: totalHeight), positions)
    }
}

#Preview {
    let vm = PhotoLibraryViewModel()
    return KeywordSelectorView(viewModel: vm)
        .frame(width: 350)
        .padding()
}
