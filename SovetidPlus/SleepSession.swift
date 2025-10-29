import CoreData

/// Core Data entity representing a single sleep interval.
@objc(SleepSession)
final class SleepSession: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var startDate: Date
    @NSManaged var endDate: Date?
    @NSManaged var createdManually: Bool
}

extension SleepSession {
    /// Convenience fetch request ordering sessions by the most recent first.
    @nonobjc class func fetchRequest() -> NSFetchRequest<SleepSession> {
        let request = NSFetchRequest<SleepSession>(entityName: "SleepSession")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SleepSession.startDate, ascending: false)]
        return request
    }

    /// Indicates whether the session is still ongoing.
    var isActive: Bool {
        endDate == nil
    }

    /// Returns the duration in seconds if the session has ended.
    var duration: TimeInterval? {
        guard let endDate else { return nil }
        return endDate.timeIntervalSince(startDate)
    }

    /// Formats the session's duration as a short string suitable for display.
    var formattedDuration: String {
        guard let duration else { return "--" }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .short
        return formatter.string(from: duration) ?? "--"
    }

    /// Formats the start and end (or current) time as a human-readable range.
    var formattedTimeRange: String {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        return "\(timeFormatter.string(from: startDate)) – \(timeFormatter.string(from: endDate ?? Date()))"
    }
}
