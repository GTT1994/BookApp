import SwiftUI

struct BookCoverView: View {
    let book: Book

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            AsyncImage(url: book.coverImageURL) { phase in
                if case .success(let image) = phase {
                    image.resizable().aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6).fill(Color.secondary.opacity(0.15))
                        Image(systemName: "book.closed")
                            .font(.title)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 100, height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            Text(book.title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
            Text(book.author)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(width: 100, alignment: .leading)
    }
}
