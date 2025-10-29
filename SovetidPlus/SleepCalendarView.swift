import CoreData
import SwiftUI

struct SleepCalendarView: View {
    @EnvironmentObject private var store: SleepStore
    @Environment(\.colorScheme) private var colorScheme

    @State private var currentMonth: Date = Calendar.current.startOfMonth(for: Date())
    @State private var selectedDate: Date = Date()

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "da_DK")
        calendar.firstWeekday = 2
        return calendar
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        formatter.locale = Locale(identifier: "da_DK")
        return formatter.string(from: currentMonth)
    }

    private var weekdaySymbols: [String] {
        var symbols = calendar.shortWeekdaySymbols
        let firstWeekdayIndex = calendar.firstWeekday - 1
        if firstWeekdayIndex > 0 {
            let prefix = symbols[..<firstWeekdayIndex]
            symbols.removeFirst(firstWeekdayIndex)
            symbols.append(contentsOf: prefix)
        }
        return symbols
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                weekdayHeader
                calendarGrid
                dayDetail
            }
            .padding(24)
        }
        .background(backgroundColor.ignoresSafeArea())
        .navigationTitle("Søvnkalender")
        .toolbar(.visible, for: .navigationBar)
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? AppColors.backgroundDark : AppColors.backgroundLight
    }

    private var header: some View {
        HStack {
            Button(action: { withAnimation(.easeInOut) { shiftMonth(-1) } }) {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .padding(10)
            }
            .buttonStyle(ScaleButtonStyle())
            Spacer()
            Text(monthTitle)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)
            Spacer()
            Button(action: { withAnimation(.easeInOut) { shiftMonth(1) } }) {
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .padding(10)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppColors.accentSurface.opacity(colorScheme == .dark ? 0.6 : 0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var weekdayHeader: some View {
        HStack {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var calendarGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 7), spacing: 12) {
            ForEach(Array(daysForCurrentMonth.enumerated()), id: \.offset) { _, date in
                if let date {
                    dayCell(for: date)
                } else {
                    Color.clear.frame(height: 52)
                }
            }
        }
    }

    private var dayDetail: some View {
        VStack(alignment: .leading, spacing: 16) {
            let daySessions = store.sessions(on: selectedDate)
            Text(formattedDate(selectedDate))
                .font(.title3.weight(.semibold))
            Text("Samlet søvn: \(formattedDuration(store.totalSleepDuration(on: selectedDate)))")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if daySessions.isEmpty {
                Text("Ingen registreringer fundet.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(AppColors.accentSurface.opacity(colorScheme == .dark ? 0.6 : 0.4))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            } else {
                VStack(spacing: 12) {
                    ForEach(daySessions, id: \.objectID) { session in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(session.formattedTimeRange)
                                .font(.headline)
                            Text(session.formattedDuration)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(AppColors.accentSurface.opacity(colorScheme == .dark ? 0.6 : 0.4))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    private func dayCell(for date: Date) -> some View {
        let total = store.totalSleepDuration(on: date)
        let hours = total / 3600
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let inCurrentMonth = calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)

        return Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                selectedDate = date
            }
        } label: {
            VStack(spacing: 6) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.headline)
                    .foregroundStyle(inCurrentMonth ? Color.primary : Color.secondary.opacity(0.4))
                if hours > 0 {
                    Text(formattedDuration(total))
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.softCardSurface.opacity(colorScheme == .dark ? 0.75 : 0.6))
                        .clipShape(Capsule())
                        .foregroundStyle(Color.primary)
                        .overlay(
                            Capsule()
                                .stroke(AppColors.accent.opacity(0.35), lineWidth: 1)
                        )
                } else {
                    Circle()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(width: 6, height: 6)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppColors.accentSurface.opacity(colorScheme == .dark ? 0.55 : 0.35))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(AppColors.accent.opacity(isSelected ? 0.6 : 0), lineWidth: 2)
            )
            .shadow(color: isSelected ? AppColors.accent.opacity(0.35) : .clear, radius: 12, x: 0, y: 6)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var daysForCurrentMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else { return [] }
        var days: [Date?] = []
        let firstDay = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let adjustment = (firstWeekday - calendar.firstWeekday + 7) % 7
        days.append(contentsOf: Array(repeating: nil, count: adjustment))

        var date = firstDay
        while date < monthInterval.end {
            days.append(date)
            guard let next = calendar.date(byAdding: .day, value: 1, to: date) else { break }
            date = next
        }
        return days
    }

    private func shiftMonth(_ value: Int) {
        guard let newDate = calendar.date(byAdding: .month, value: value, to: currentMonth) else { return }
        let normalized = calendar.startOfMonth(for: newDate)
        currentMonth = normalized
        if !calendar.isDate(selectedDate, equalTo: normalized, toGranularity: .month) {
            selectedDate = normalized
        }
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = duration >= 3600 ? [.hour, .minute] : [.minute]
        formatter.unitsStyle = .abbreviated
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.calendar?.locale = Locale(identifier: "da_DK")
        return formatter.string(from: duration) ?? "0 min"
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "da_DK")
        formatter.setLocalizedDateFormatFromTemplate("EEEE d. MMMM")
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        SleepCalendarView()
            .environmentObject(SleepStore(context: PersistenceController.shared.container.viewContext))
    }
}
