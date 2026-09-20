import SwiftUI
import VisionKit

/// Wraps VisionKit's live camera scanner, recognizing both barcodes (for a fast, reliable ISBN
/// lookup) and free text (for reading a book's spine) at the same time.
struct ScannerView: UIViewControllerRepresentable {
    var onTextRecognized: (String) -> Void
    var onBarcodeRecognized: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [
                .barcode(symbologies: [.ean13, .ean8, .upce]),
                .text(languages: ["en"])
            ],
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ scanner: DataScannerViewController, context: Context) {
        if !scanner.isScanning {
            try? scanner.startScanning()
        }
    }

    static func dismantleUIViewController(_ scanner: DataScannerViewController, coordinator: Coordinator) {
        scanner.stopScanning()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onTextRecognized: onTextRecognized, onBarcodeRecognized: onBarcodeRecognized)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onTextRecognized: (String) -> Void
        let onBarcodeRecognized: (String) -> Void

        init(onTextRecognized: @escaping (String) -> Void, onBarcodeRecognized: @escaping (String) -> Void) {
            self.onTextRecognized = onTextRecognized
            self.onBarcodeRecognized = onBarcodeRecognized
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            for item in addedItems {
                switch item {
                case .barcode(let barcode):
                    if let payload = barcode.payloadStringValue {
                        onBarcodeRecognized(payload)
                    }
                case .text(let text):
                    onTextRecognized(text.transcript)
                @unknown default:
                    break
                }
            }
        }
    }
}
