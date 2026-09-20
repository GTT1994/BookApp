# BookApp

Scan the spine of a physical book with your iPhone's camera and add it straight to a virtual
bookshelf. Your shelf syncs across your own devices via iCloud.

## How it works

- **Scanning** (`BookApp/Scanning`): a live camera view built on VisionKit's `DataScannerViewController`
  reads both barcodes and on-screen text at the same time. A barcode (EAN-13/EAN-8/UPC-E) is
  treated as an ISBN and looked up directly; spine text is debounced and sent to a search as the
  camera holds steady on it.
- **Lookup** (`BookApp/Services/BookLookupService.swift`): queries the free
  [Google Books API](https://developers.google.com/books) by ISBN or free text and returns
  candidate matches (title, author, cover thumbnail).
- **Confirmation**: matches are shown in a picker so you confirm the right book before it's saved
  — spine OCR is inherently a bit noisy, so this avoids adding the wrong book.
- **Manual add**: if scanning doesn't find anything (bad lighting, a device that doesn't support
  live scanning, etc.), you can search Google Books directly by title/author/ISBN.
- **Storage & sync** (`BookApp/Models/Book.swift`, `BookApp/App/BookAppApp.swift`): books are
  stored with SwiftData, configured with `cloudKitDatabase: .automatic` so your shelf syncs
  across your devices via your iCloud account — no backend server required.

## Project structure

This project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the `.xcodeproj`
from [`project.yml`](project.yml), rather than committing the Xcode project file itself. This
keeps the repo readable and avoids merge-conflict-prone `.pbxproj` diffs. The generated
`.xcodeproj`, `Info.plist`, and entitlements file are gitignored — you regenerate them locally
whenever you check out or change `project.yml`.

```
BookApp/
├── project.yml              # XcodeGen project spec
├── BookApp/
│   ├── App/                 # App entry point + SwiftData container setup
│   ├── Models/              # SwiftData model (Book)
│   ├── Services/            # Google Books API client
│   ├── Scanning/            # VisionKit camera scanner + scan screen
│   ├── Views/                # Bookshelf grid, detail, manual search, match picker
│   └── Resources/           # Asset catalog (app icon, accent color)
```

## First-time setup

You'll need a Mac with Xcode installed (this app needs the iOS 17 SDK, so Xcode 15 or later).

1. **Install Xcode** from the Mac App Store, if you haven't already.
2. **Install [Homebrew](https://brew.sh)** if you don't have it, then install XcodeGen:
   ```sh
   brew install xcodegen
   ```
3. **Generate the Xcode project:**
   ```sh
   cd BookApp
   xcodegen generate
   ```
   This creates `BookApp.xcodeproj`. Open it with `open BookApp.xcodeproj`.
4. **Set your signing team.** In Xcode, select the `BookApp` target → *Signing & Capabilities* →
   choose your Apple ID/team under *Team*. This also updates the bundle identifier's provisioning.
5. **Enable iCloud/CloudKit.** The entitlements already request an iCloud container and CloudKit
   service, but the first time you build, Xcode needs to actually provision that container on
   your account:
   - In *Signing & Capabilities*, click **+ Capability** → add **iCloud** → check **CloudKit**.
   - Xcode will offer to create a new container (e.g. `iCloud.com.gtt1994.BookApp`) — accept it.
   - You'll need an active (free or paid) Apple Developer account signed into Xcode for this.
6. **Run on a physical iPhone.** Live spine/barcode scanning uses the camera via
   `DataScannerViewController`, which **does not work in the iOS Simulator** — you must run on a
   real device (iOS 16+) to test scanning. The manual-search fallback works in the Simulator too.

Whenever you pull changes that touch `project.yml` (or add/remove/move Swift files), re-run
`xcodegen generate` to regenerate the project.

## Notes for shipping later

- Replace the bundle identifier (`com.gtt1994.BookApp` in `project.yml`) with your own reverse-DNS
  identifier if you plan to distribute the app.
- Add a real app icon image to `BookApp/Resources/Assets.xcassets/AppIcon.appiconset` before
  submitting to the App Store — right now it's an empty placeholder slot.
- The Google Books API works without a key for light usage; if you hit rate limits, get a free
  API key from the [Google Cloud Console](https://console.cloud.google.com/) and add it as a
  `key` query parameter in `BookLookupService`.
