import Combine
import CoreData
import Foundation

@MainActor
final class SleepStore: ObservableObject {
    @Published private(set) var sessions: [SleepSession] = []

    private let context: NSManagedObjectContext
    private let calendar: Calendar
    private var contextObserver: NSObjectProtocol?

    init(context: NSManagedObjectContext, calendar: Calendar = .current) {
        self.context = context
        self.calendar = calendar
        contextObserver = NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: context,
            queue: nil
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.fetchSessions()
            }
        }
        fetchSessions()
    }

    deinit {
        if let observer = contextObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func fetchSessions() {
        context.perform { [weak self] in
            guard let self else { return }
            do {
                let request: NSFetchRequest<SleepSession> = SleepSession.fetchRequest()
                request.returnsObjectsAsFaults = false
                self.sessions = try self.context.fetch(request)
            } catch {
                print("Failed to fetch sessions: \(error)")
                self.sessions = []
            }
        }
    }

    var activeSession: SleepSession? {
        sessions.first { $0.isActive }
    }

    func startSession() {
        guard activeSession == nil else { return }

        let session = SleepSession(context: context)
        session.id = UUID()
        session.startDate = Date()
        session.endDate = nil
        session.createdManually = false
        saveContext()
    }

    func stopSession() {
        guard let session = activeSession else { return }
        session.endDate = Date()
        saveContext()
    }

    func addSession(start: Date, end: Date) -> Bool {
        let now = Date()
        guard end > start, start <= now, end <= now else { return false }
        let session = SleepSession(context: context)
        session.id = UUID()
        session.startDate = start
        session.endDate = end
        session.createdManually = true
        saveContext()
        return true
    }

    private func saveContext() {
        guard context.hasChanges else { return }
        context.perform { [weak self] in
            guard let self else { return }
            do {
                try self.context.save()
                self.fetchSessions()
            } catch {
                self.context.rollback()
                print("Failed to save: \(error)")
                self.fetchSessions()
            }
        }
    }

    func sessions(on date: Date) -> [SleepSession] {
        sessions.filter { session in
            calendar.isDate(session.startDate, inSameDayAs: date)
        }
        .sorted { $0.startDate < $1.startDate }
    }

    func totalSleepDuration(on date: Date) -> TimeInterval {
        sessions(on: date)
            .compactMap { $0.duration ?? ($0.endDate == nil ? Date().timeIntervalSince($0.startDate) : nil) }
            .reduce(0, +)
    }
}
