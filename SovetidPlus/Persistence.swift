import CoreData

/// Bootstraps the Core Data stack used throughout the application.
final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    /// Creates a new persistence controller optionally configured with an
    /// in-memory store, which is handy for SwiftUI previews and tests.
    private init(inMemory: Bool = false) {
        let model = PersistenceController.managedObjectModel
        container = NSPersistentContainer(name: "BabySleepTracker", managedObjectModel: model)

        if inMemory {
            let storeDescription = NSPersistentStoreDescription()
            storeDescription.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [storeDescription]
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    /// Programmatic managed object model describing the `SleepSession` entity.
    private static var managedObjectModel: NSManagedObjectModel = {
        let model = NSManagedObjectModel()

        let sleepSessionEntity = NSEntityDescription()
        sleepSessionEntity.name = "SleepSession"
        sleepSessionEntity.managedObjectClassName = NSStringFromClass(SleepSession.self)

        let idAttribute = NSAttributeDescription()
        idAttribute.name = "id"
        idAttribute.attributeType = .UUIDAttributeType
        idAttribute.isOptional = false
        idAttribute.defaultValue = UUID()

        let startDateAttribute = NSAttributeDescription()
        startDateAttribute.name = "startDate"
        startDateAttribute.attributeType = .dateAttributeType
        startDateAttribute.isOptional = false

        let endDateAttribute = NSAttributeDescription()
        endDateAttribute.name = "endDate"
        endDateAttribute.attributeType = .dateAttributeType
        endDateAttribute.isOptional = true

        let createdManuallyAttribute = NSAttributeDescription()
        createdManuallyAttribute.name = "createdManually"
        createdManuallyAttribute.attributeType = .booleanAttributeType
        createdManuallyAttribute.isOptional = false
        createdManuallyAttribute.defaultValue = false

        sleepSessionEntity.properties = [idAttribute, startDateAttribute, endDateAttribute, createdManuallyAttribute]

        model.entities = [sleepSessionEntity]
        return model
    }()
}
