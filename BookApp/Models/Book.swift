import Foundation
import SwiftData

@Model
final class Book {
    var title: String = ""
    var author: String = ""
    var isbn: String?
    var coverImageURL: URL?
    var dateAdded: Date = Date.now
    var notes: String?

    init(
        title: String,
        author: String,
        isbn: String? = nil,
        coverImageURL: URL? = nil,
        dateAdded: Date = .now,
        notes: String? = nil
    ) {
        self.title = title
        self.author = author
        self.isbn = isbn
        self.coverImageURL = coverImageURL
        self.dateAdded = dateAdded
        self.notes = notes
    }
}
