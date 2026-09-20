import SwiftUI
import SwiftData

struct BookshelfView: View {
    @Query(sort: \Book.dateAdded, order: .reverse) private var books: [Book]
    @State private var showScanner = false

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 20)]

    var body: some View {
        NavigationStack {
            Group {
                if books.isEmpty {
                    ContentUnavailableView(
                        "Your shelf is empty",
                        systemImage: "books.vertical",
                        description: Text("Scan a book's spine or barcode to add your first book.")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 24) {
                            ForEach(books) { book in
                                NavigationLink(value: book) {
                                    BookCoverView(book: book)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My Bookshelf")
            .navigationDestination(for: Book.self) { book in
                BookDetailView(book: book)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showScanner = true
                    } label: {
                        Label("Scan Book", systemImage: "camera.viewfinder")
                    }
                }
            }
            .fullScreenCover(isPresented: $showScanner) {
                NavigationStack {
                    ScanBookView()
                }
            }
        }
    }
}
