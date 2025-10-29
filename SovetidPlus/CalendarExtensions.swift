import Foundation

extension Calendar {
    /// Returns a date representing the first day of the month that contains the
    /// provided date.
    func startOfMonth(for date: Date) -> Date {
        dateInterval(of: .month, for: date)?.start ?? date
    }
}
