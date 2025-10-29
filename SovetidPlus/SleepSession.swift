import CoreData

@objc(SleepSession)
final class SleepSession: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var startDate: Date
    @NSManaged var endDate: Date?
    @NSManaged var createdManually: Bool
}

extension SleepSession {
    @nonobjc class func fetchRequest() -> NSFetchRequest<SleepSession> {
        let request = NSFetchRequest<SleepSession>(entityName: "SleepSession")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SleepSession.startDate, ascending: false)]
        return request
    }

    var isActive: Bool {
        endDate == nil
    }

    var duration: TimeInterval? {
        guard let endDate else { return nil }
        return endDate.timeIntervalSince(startDate)
    }

    var formattedDuration: String {
        guard let duration else { return "--" }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .short
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.calendar?.locale = Locale(identifier: "da_DK")
        return formatter.string(from: duration) ?? "--"
    }

    var formattedTimeRange: String {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        timeFormatter.locale = Locale(identifier: "da_DK")
        return "\(timeFormatter.string(from: startDate)) – \(timeFormatter.string(from: endDate ?? Date()))"
    }
}
