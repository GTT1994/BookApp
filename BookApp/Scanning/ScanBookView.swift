import SwiftUI
import SwiftData
import VisionKit

/// The scanning screen: shows the live camera feed, reads spine text and barcodes as they come
/// in, looks candidates up, and lets the user confirm a match before it's added to the shelf.
struct ScanBookView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let lookupService = BookLookupService()

    @State private var candidateResults: [BookResult] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    @State private var statusMessage = "Point your camera at a book's spine or barcode"
    @State private var showManualSearch = false

    var body: some View {
        ZStack(alignment: .bottom) {
            if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                ScannerView(onTextRecognized: handleText, onBarcodeRecognized: handleBarcode)
                    .ignoresSafeArea()
            } else {
                ContentUnavailableView(
                    "Scanning Unavailable",
                    systemImage: "camera.fill",
                    description: Text("This device doesn't support live scanning (the Simulator can't access a camera). Try adding a book manually instead.")
                )
            }

            VStack(spacing: 12) {
                Text(statusMessage)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())

                Button("Add Manually") { showManualSearch = true }
                    .buttonStyle(.borderedProminent)
            }
            .padding(.bottom, 32)
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
        .sheet(isPresented: $showManualSearch) {
            ManualSearchView { result in
                addBook(result)
                dismiss()
            }
        }
        .sheet(isPresented: Binding(
            get: { !candidateResults.isEmpty },
            set: { isPresented in if !isPresented { candidateResults = [] } }
        )) {
            BookMatchPickerView(
                results: candidateResults,
                onSelect: { result in
                    addBook(result)
                    dismiss()
                },
                onCancel: { candidateResults = [] }
            )
        }
        .onDisappear { searchTask?.cancel() }
    }

    private func handleBarcode(_ isbn: String) {
        guard !isSearching else { return }
        searchTask?.cancel()
        isSearching = true
        statusMessage = "Looking up ISBN \(isbn)…"
        searchTask = Task {
            defer { isSearching = false }
            do {
                if let result = try await lookupService.searchByISBN(isbn) {
                    candidateResults = [result]
                    statusMessage = "Found a match!"
                } else {
                    statusMessage = "No match found for that barcode."
                }
            } catch {
                statusMessage = error.localizedDescription
            }
        }
    }

    private func handleText(_ transcript: String) {
        guard !isSearching, transcript.count > 3 else { return }
        searchTask?.cancel()
        searchTask = Task {
            // Debounce: wait for the recognized text to settle before spending an API call on it.
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }
            isSearching = true
            defer { isSearching = false }
            statusMessage = "Searching for “\(transcript)”…"
            do {
                let results = try await lookupService.search(query: transcript)
                if !results.isEmpty {
                    candidateResults = results
                    statusMessage = "Found \(results.count) possible match(es)."
                } else {
                    statusMessage = "No matches yet — keep scanning the spine."
                }
            } catch {
                statusMessage = error.localizedDescription
            }
        }
    }

    private func addBook(_ result: BookResult) {
        let book = Book(
            title: result.title,
            author: result.authors.joined(separator: ", "),
            isbn: result.isbn,
            coverImageURL: result.thumbnailURL
        )
        modelContext.insert(book)
    }
}
