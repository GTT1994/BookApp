import Foundation

struct BookResult: Identifiable, Hashable {
    let id: String
    let title: String
    let authors: [String]
    let isbn: String?
    let thumbnailURL: URL?
}

enum BookLookupError: LocalizedError {
    case badResponse
    case server(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .badResponse:
            return "The server sent back something unexpected."
        case .server(let statusCode):
            if statusCode == 429 {
                return "Too many requests right now — wait a moment and try again."
            }
            return "Open Library returned an error (\(statusCode))."
        }
    }
}

/// Looks books up via the Open Library API (openlibrary.org), which is free with no API key,
/// registration, or billing required.
struct BookLookupService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Searches by free-text query (title, author, or a raw OCR transcript from a spine).
    func search(query: String) async throws -> [BookResult] {
        var components = URLComponents(string: "https://openlibrary.org/search.json")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: "10"),
            URLQueryItem(name: "fields", value: "key,title,author_name,isbn,cover_i")
        ]
        guard let url = components.url else { throw BookLookupError.badResponse }

        let data = try await fetch(url)
        let decoded = try JSONDecoder().decode(OpenLibrarySearchResponse.self, from: data)
        return decoded.docs.map { $0.asBookResult }
    }

    /// Looks up a single book by its ISBN, typically from a scanned barcode.
    func searchByISBN(_ isbn: String) async throws -> BookResult? {
        var components = URLComponents(string: "https://openlibrary.org/api/books")!
        components.queryItems = [
            URLQueryItem(name: "bibkeys", value: "ISBN:\(isbn)"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "jscmd", value: "data")
        ]
        guard let url = components.url else { throw BookLookupError.badResponse }

        let data = try await fetch(url)
        let decoded = try JSONDecoder().decode([String: OpenLibraryBookData].self, from: data)
        guard let bookData = decoded["ISBN:\(isbn)"] else { return nil }
        return bookData.asBookResult(isbn: isbn)
    }

    private func fetch(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        // Open Library asks API consumers to identify themselves via User-Agent as good practice.
        request.setValue("BookApp/1.0 (iOS bookshelf app)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw BookLookupError.badResponse }
        guard http.statusCode == 200 else { throw BookLookupError.server(statusCode: http.statusCode) }
        return data
    }
}

private struct OpenLibrarySearchResponse: Decodable {
    let docs: [Doc]

    struct Doc: Decodable {
        let key: String
        let title: String
        let author_name: [String]?
        let isbn: [String]?
        let cover_i: Int?

        var asBookResult: BookResult {
            BookResult(
                id: key,
                title: title,
                authors: author_name ?? ["Unknown Author"],
                isbn: isbn?.first,
                thumbnailURL: cover_i.flatMap { URL(string: "https://covers.openlibrary.org/b/id/\($0)-M.jpg") }
            )
        }
    }
}

private struct OpenLibraryBookData: Decodable {
    let title: String
    let authors: [Author]?
    let cover: Cover?

    struct Author: Decodable {
        let name: String
    }

    struct Cover: Decodable {
        let small: String?
        let medium: String?
        let large: String?
    }

    func asBookResult(isbn: String) -> BookResult {
        BookResult(
            id: "ISBN:\(isbn)",
            title: title,
            authors: authors?.map(\.name) ?? ["Unknown Author"],
            isbn: isbn,
            thumbnailURL: (cover?.medium ?? cover?.small).flatMap(URL.init)
        )
    }
}
