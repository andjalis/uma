import SwiftUI
import CoreData

@main
struct SovetidPlusApp: App {
    private let persistenceController: PersistenceController
    @StateObject private var store: SleepStore

    init() {
        let persistenceController = PersistenceController.shared
        self.persistenceController = persistenceController
        let context = persistenceController.container.viewContext
        _store = StateObject(wrappedValue: SleepStore(context: context))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(store)
        }
    }
}
