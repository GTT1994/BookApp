import SwiftUI
import SwiftData

@main
struct BookAppApp: App {
    let sharedModelContainer: ModelContainer = {
        let schema = Schema([Book.self])
        // Local-only storage for now: CloudKit sync requires a paid Apple Developer Program
        // membership (free Personal Teams can't use the iCloud capability). To re-enable sync
        // later, pass `cloudKitDatabase: .automatic` here and re-add the iCloud/CloudKit
        // entitlement in project.yml (see README).
        let configuration = ModelConfiguration(schema: schema)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            BookshelfView()
        }
        .modelContainer(sharedModelContainer)
    }
}
