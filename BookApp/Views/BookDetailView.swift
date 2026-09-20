import SwiftUI
import SwiftData

struct BookDetailView: View {
    @Bindable var book: Book

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AsyncImage(url: book.coverImageURL) { phase in
                    if case .success(let image) = phase {
                        image.resizable().aspectRatio(contentMode: .fit)
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.15))
                            .frame(height: 220)
                    }
                }
                .frame(maxWidth: 200)
                .frame(maxWidth: .infinity)

                Text(book.title).font(.title2).bold()
                Text(book.author).font(.headline).foregroundStyle(.secondary)

                if let isbn = book.isbn {
                    Text("ISBN: \(isbn)").font(.footnote).foregroundStyle(.secondary)
                }
                Text("Added \(book.dateAdded.formatted(date: .abbreviated, time: .omitted))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                TextField(
                    "Notes",
                    text: Binding(get: { book.notes ?? "" }, set: { book.notes = $0 }),
                    axis: .vertical
                )
                .textFieldStyle(.roundedBorder)
            }
            .padding()
        }
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    modelContext.delete(book)
                    dismiss()
                } label: {
                    Label("Remove", systemImage: "trash")
                }
            }
        }
    }
}
