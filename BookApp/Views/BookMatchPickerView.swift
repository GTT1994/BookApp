import SwiftUI

/// Shown after a scan finds one or more candidate matches, so the user confirms which (if any)
/// is the book they scanned before it's saved to their shelf.
struct BookMatchPickerView: View {
    let results: [BookResult]
    let onSelect: (BookResult) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            List(results) { result in
                Button {
                    onSelect(result)
                } label: {
                    HStack(spacing: 12) {
                        AsyncImage(url: result.thumbnailURL) { phase in
                            if case .success(let image) = phase {
                                image.resizable().aspectRatio(contentMode: .fit)
                            } else {
                                Image(systemName: "book.closed")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(width: 44, height: 64)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.title).font(.headline)
                            Text(result.authors.joined(separator: ", "))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Is this your book?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
