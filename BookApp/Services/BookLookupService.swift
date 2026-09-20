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
    case server(statusCode: Int, message: String?)

    var errorDescription: String? {
        switch self {
        case .badResponse:
            return "The server sent back something unexpected."
        case .server(let statusCode, let message):
            if statusCode == 429 {
                return "Rate limit hit (429) — see README for adding your own Google Books API key."
            }
            return "Google Books returned an error (\(statusCode))\(message.map { ": \($0)" } ?? "")."
        }
    }
}

struct BookLookupService {
    private let session: URLSession

    /// A free API key from https://console.cloud.google.com/ (Books API enabled). Without one,
    /// requests share a small daily quota with everyone else who also has no key, which can run
    /// dry — see README.md for how to add your own.
    private var apiKey: String? {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "GoogleBooksAPIKey") as? String,
              !key.isEmpty else { return nil }
        return key
    }

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Searches the Google Books catalog with a free-text query (title, author, or a raw OCR transcript).
    func search(query: String) async throws -> [BookResult] {
        var components = URLComponents(string: "https://www.googleapis.com/books/v1/volumes")!
        var queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "maxResults", value: "10")
        ]
        if let apiKey {
            queryItems.append(URLQueryItem(name: "key", value: apiKey))
        }
        components.queryItems = queryItems
        guard let url = components.url else { throw BookLookupError.badResponse }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse else { throw BookLookupError.badResponse }
        guard http.statusCode == 200 else {
            let message = try? JSONDecoder().decode(GoogleBooksErrorResponse.self, from: data).error.message
            throw BookLookupError.server(statusCode: http.statusCode, message: message)
        }

        let decoded = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
        return (decoded.items ?? []).map { $0.asBookResult }
    }

    /// Looks up a single book by its ISBN, typically from a scanned barcode.
    func searchByISBN(_ isbn: String) async throws -> BookResult? {
        try await search(query: "isbn:\(isbn)").first
    }
}

private struct GoogleBooksErrorResponse: Decodable {
    let error: ErrorBody
    struct ErrorBody: Decodable {
        let message: String
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
