import Combine
import CoreData
import Foundation

/// Source of truth for the app's sleep data backed by Core Data.
///
/// The store exposes the in-memory list of ``SleepSession`` objects that is
/// displayed by the UI and provides convenience helpers for starting,
/// stopping, and manually inserting sessions. All mutating work happens on the
/// main actor because SwiftUI views depend on the published `sessions`
/// collection.
@MainActor
final class SleepStore: ObservableObject {
    @Published private(set) var sessions: [SleepSession] = []

    private let context: NSManagedObjectContext
    private let calendar: Calendar

    /// Creates a new store using the supplied managed object context and
    /// calendar. The initializer fetches the most recent sessions so the UI is
    /// ready to render immediately.
    init(context: NSManagedObjectContext, calendar: Calendar = .current) {
        self.context = context
        self.calendar = calendar
        fetchSessions()
    }

    /// Refreshes the in-memory cache of sessions by fetching them from Core
    /// Data.
    func fetchSessions() {
        do {
            sessions = try context.fetch(SleepSession.fetchRequest())
        } catch {
            print("Failed to fetch sessions: \(error)")
            sessions = []
        }
    }

    /// Returns the sleep session that is currently in progress, if any.
    var activeSession: SleepSession? {
        sessions.first { $0.isActive }
    }

    /// Begins a new sleep session when no active session exists.
    func startSession() {
        guard activeSession == nil else { return }

        let session = SleepSession(context: context)
        session.id = UUID()
        session.startDate = Date()
        session.endDate = nil
        session.createdManually = false
        saveContext()
    }

    /// Stops the active sleep session by stamping its end date.
    func stopSession() {
        guard let session = activeSession else { return }
        session.endDate = Date()
        saveContext()
    }

    /// Inserts a sleep session with explicit start and end dates. The method
    /// performs minimal validation to guarantee the end is after the start and
    /// returns a boolean indicating whether the save succeeded.
    func addSession(start: Date, end: Date) -> Bool {
        guard end > start else { return false }
        let session = SleepSession(context: context)
        session.id = UUID()
        session.startDate = start
        session.endDate = end
        session.createdManually = true
        saveContext()
        return true
    }

    /// Persists any pending changes on the managed object context, rolling
    /// back on failure to keep the UI state consistent.
    private func saveContext() {
        guard context.hasChanges else { return }
        do {
            try context.save()
            fetchSessions()
        } catch {
            context.rollback()
            print("Failed to save: \(error)")
            fetchSessions()
        }
    }

    /// Returns all sleep sessions that started on the provided date,
    /// sorted chronologically.
    func sessions(on date: Date) -> [SleepSession] {
        sessions.filter { session in
            calendar.isDate(session.startDate, inSameDayAs: date)
        }
        .sorted { $0.startDate < $1.startDate }
    }

    /// Calculates the cumulative number of seconds the baby slept on the
    /// supplied date. Active sessions contribute the time elapsed so far so the
    /// UI reflects the running total.
    func totalSleepDuration(on date: Date) -> TimeInterval {
        sessions(on: date)
            .compactMap { $0.duration ?? ($0.endDate == nil ? Date().timeIntervalSince($0.startDate) : nil) }
            .reduce(0, +)
    }
}
