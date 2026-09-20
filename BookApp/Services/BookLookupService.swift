import Foundation

struct BookResult: Identifiable, Hashable {
    let id: String
    let title: String
    let authors: [String]
    let isbn: String?
    let thumbnailURL: URL?
}

enum BookLookupError: Error {
    case invalidResponse
}

struct BookLookupService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Searches the Google Books catalog with a free-text query (title, author, or a raw OCR transcript).
    func search(query: String) async throws -> [BookResult] {
        var components = URLComponents(string: "https://www.googleapis.com/books/v1/volumes")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "maxResults", value: "10")
        ]
        guard let url = components.url else { throw BookLookupError.invalidResponse }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw BookLookupError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
        return (decoded.items ?? []).map { $0.asBookResult }
    }

    /// Looks up a single book by its ISBN, typically from a scanned barcode.
    func searchByISBN(_ isbn: String) async throws -> BookResult? {
        try await search(query: "isbn:\(isbn)").first
    }
}

private struct GoogleBooksResponse: Decodable {
    let items: [Item]?

    struct Item: Decodable {
        let id: String
        let volumeInfo: VolumeInfo

        var asBookResult: BookResult {
            BookResult(
                id: id,
                title: volumeInfo.title,
                authors: volumeInfo.authors ?? ["Unknown Author"],
                isbn: volumeInfo.industryIdentifiers?.first(where: { $0.type.contains("ISBN") })?.identifier,
                thumbnailURL: volumeInfo.imageLinks?.secureThumbnailURL
            )
        }
    }

    struct VolumeInfo: Decodable {
        let title: String
        let authors: [String]?
        let industryIdentifiers: [IndustryIdentifier]?
        let imageLinks: ImageLinks?
    }

    struct IndustryIdentifier: Decodable {
        let type: String
        let identifier: String
    }

    struct ImageLinks: Decodable {
        let thumbnail: String?

        var secureThumbnailURL: URL? {
            guard let thumbnail else { return nil }
            return URL(string: thumbnail.replacingOccurrences(of: "http://", with: "https://"))
        }
    }
}
