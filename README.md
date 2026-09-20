# BookApp

Scan the spine of a physical book with your iPhone's camera and add it straight to a virtual
bookshelf.

> **Storage note:** the shelf is currently local-only (on-device). It was originally built with
> iCloud/CloudKit sync, but that requires a paid Apple Developer Program membership — free
> Personal Team accounts are blocked from the iCloud capability entirely. See
> [Re-enabling iCloud sync](#re-enabling-icloud-sync) below if you upgrade later.

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
- **Storage** (`BookApp/Models/Book.swift`, `BookApp/App/BookAppApp.swift`): books are stored
  on-device with SwiftData. No backend server required, but the shelf doesn't currently sync
  across your devices (see the storage note above).

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
4. **Set your signing team.** `project.yml` has a `DEVELOPMENT_TEAM` filled in for the original
   author's Personal Team — in Xcode, select the `BookApp` target → *Signing & Capabilities* →
   change *Team* to your own Apple ID/team (or edit `DEVELOPMENT_TEAM` in `project.yml` and
   re-run `xcodegen generate`).
5. **Get a free Google Books API key** (strongly recommended — see the note below):
   - Go to the [Google Cloud Console](https://console.cloud.google.com/), create/select a project.
   - *APIs & Services → Library* → search **Books API** → **Enable**.
   - *APIs & Services → Credentials* → **Create Credentials → API Key** → copy it.
   - Copy `Configs/Secrets.xcconfig.example` to `Configs/Secrets.xcconfig` (gitignored, so your
     key never gets committed) and paste your key after `GOOGLE_BOOKS_API_KEY =`.
   - Re-run `xcodegen generate` and rebuild.
6. **Run on a physical iPhone.** Live spine/barcode scanning uses the camera via
   `DataScannerViewController`, which **does not work in the iOS Simulator** — you must run on a
   real device (iOS 16+) to test scanning. The manual-search fallback works in the Simulator too.

Whenever you pull changes that touch `project.yml` (or add/remove/move Swift files), re-run
`xcodegen generate` to regenerate the project.

> **Why the API key matters:** without one, requests share a small anonymous daily quota with
> *everyone* who also has no key — it's easy to exhaust (a few hundred requests/day, shared
> globally) and once it's gone every search fails with a 429 "quota exceeded" error, which looks
> just like "no matches found" if you're not checking Xcode's console. A free key gives you your
> own generous per-day quota.

## Re-enabling iCloud sync

If you later upgrade to the paid Apple Developer Program, you can turn CloudKit sync back on:

1. In `BookApp/App/BookAppApp.swift`, change:
   ```swift
   let configuration = ModelConfiguration(schema: schema)
   ```
   back to:
   ```swift
   let configuration = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
   ```
2. In `project.yml`, add back an `entitlements` block under the `BookApp` target:
   ```yaml
   entitlements:
     path: Generated/BookApp.entitlements
     properties:
       com.apple.developer.icloud-container-identifiers:
         - "iCloud.$(PRODUCT_BUNDLE_IDENTIFIER)"
       com.apple.developer.icloud-services:
         - CloudKit
       com.apple.developer.ubiquity-kvstore-identifier: "$(TeamIdentifierPrefix)$(CFBundleIdentifier)"
   ```
3. Run `xcodegen generate`, reopen the project, and in *Signing & Capabilities* add the **iCloud**
   capability with **CloudKit** checked (Xcode will offer to create a container — accept it).

## Notes for shipping later

- Replace the bundle identifier (`com.gtt1994.BookApp` in `project.yml`) with your own reverse-DNS
  identifier if you plan to distribute the app.
- Add a real app icon image to `BookApp/Resources/Assets.xcassets/AppIcon.appiconset` before
  submitting to the App Store — right now it's an empty placeholder slot.
- Make sure `Configs/Secrets.xcconfig` has your Google Books API key set (see setup step 5) —
  without it you're on the easily-exhausted shared anonymous quota.
