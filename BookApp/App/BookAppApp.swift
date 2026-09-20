import SwiftUI
import SwiftData

@main
struct BookAppApp: App {
    let sharedModelContainer: ModelContainer = {
        let schema = Schema([Book.self])
        let configuration = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
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
