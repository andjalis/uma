import Combine
import CoreData
import SwiftUI

private enum BabyPalette {
    static let softBeige = Color(red: 0.97, green: 0.94, blue: 0.89)
    static let warmSand = Color(red: 0.94, green: 0.87, blue: 0.78)
    static let morningMist = Color(red: 0.86, green: 0.92, blue: 0.95)
    static let paleSage = Color(red: 0.82, green: 0.9, blue: 0.82)
    static let mutedSage = Color(red: 0.68, green: 0.79, blue: 0.72)
    static let duskBlue = Color(red: 0.46, green: 0.59, blue: 0.7)
    static let deepSage = Color(red: 0.43, green: 0.56, blue: 0.52)
    static let eveningTeal = Color(red: 0.32, green: 0.48, blue: 0.5)
}

/// Landing screen that manages live sleep tracking, quick stats, and entry
/// points into the calendar and manual logging flows.
struct ContentView: View {
    @EnvironmentObject private var store: SleepStore
    @Environment(\.colorScheme) private var colorScheme

    @State private var showManualEntry = false
    @State private var now = Date()
    @State private var animateGlow = false

    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var isSleeping: Bool { store.activeSession != nil }
    private var activeSession: SleepSession? { store.activeSession }
    private var lastCompletedSession: SleepSession? { store.sessions.first { !$0.isActive } }

    private var todayDuration: TimeInterval {
        store.totalSleepDuration(on: Date())
    }

    private var gradientBackground: LinearGradient {
        let colors: [Color]
        if colorScheme == .dark {
            colors = [BabyPalette.eveningTeal, BabyPalette.deepSage]
        } else {
            colors = [BabyPalette.softBeige, BabyPalette.morningMist]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let safeInsets = proxy.safeAreaInsets
                let availableHeight = proxy.size.height - safeInsets.top - safeInsets.bottom
                let proposedSize = min(proxy.size.width * 0.7, availableHeight * 0.55)
                let buttonDiameter = max(proposedSize, 240)
                let bottomPadding = max(safeInsets.bottom + 24, 40)

                ZStack {
                    gradientBackground
                        .ignoresSafeArea()

                    VStack(spacing: 24) {
                        header
                        Spacer(minLength: 12)
                        sleepButton(size: buttonDiameter)
                        statusView
                        quickStats
                        recentSessionsView
                        Spacer(minLength: 20)
                        manualEntryButton
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, bottomPadding)
                    .padding(.top, safeInsets.top + 20)
                }
            }
        }
        .sheet(isPresented: $showManualEntry) {
            ManualEntryView { start, end in
                let success = store.addSession(start: start, end: end)
                if !success { return false }
                store.fetchSessions()
                return true
            }
            .presentationDetents([.medium])
        }
        .onReceive(timer) { value in
            now = value
        }
        .onAppear {
            store.fetchSessions()
        }
        .onChange(of: isSleeping) { newValue in
            if newValue {
                startGlow()
            } else {
                animateGlow = false
            }
        }
        .task {
            if isSleeping { startGlow() }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func sleepButton(size: CGFloat) -> some View {
        Button(action: toggleSleepState) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isSleeping ? [BabyPalette.deepSage, BabyPalette.eveningTeal] : [BabyPalette.morningMist, BabyPalette.paleSage],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    .shadow(color: (isSleeping ? BabyPalette.deepSage : BabyPalette.mutedSage).opacity(0.35), radius: 34, x: 0, y: 26)

                if isSleeping {
                    Circle()
                        .stroke(BabyPalette.deepSage.opacity(0.45), lineWidth: 12)
                        .frame(width: size + 44, height: size + 44)
                        .scaleEffect(animateGlow ? 1.12 : 0.94)
                        .opacity(animateGlow ? 0.45 : 0.18)
                        .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: animateGlow)
                }

                VStack(spacing: 14) {
                    Image(systemName: isSleeping ? "pause.fill" : "play.fill")
                        .font(.system(size: max(36, size * 0.16), weight: .semibold))
                        .foregroundStyle(.white.opacity(0.95))
                    Text(isSleeping ? "Pause Nap" : "Start Nap")
                        .font(.system(size: max(28, size * 0.12), weight: .bold))
                        .foregroundStyle(.white)
                    Text(isSleeping ? "Snoozing softly" : "Ready for cuddles")
                        .font(.system(size: max(16, size * 0.07), weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(isSleeping ? "Stop nap" : "Start nap")
    }

    private var headerSubtitle: String {
        isSleeping ? "Tap to pause when baby wakes" : "Tap when baby drifts off"
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Baby Nap")
                    .font(.largeTitle.weight(.bold))
                Text(headerSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            NavigationLink {
                SleepCalendarView()
            } label: {
                Image(systemName: "calendar")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.primary)
                    .padding(14)
                    .background(
                        Circle()
                            .fill(BabyPalette.morningMist.opacity(0.7))
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 6)
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    private var statusView: some View {
        VStack(spacing: 8) {
            if let session = activeSession {
                let elapsed = max(0, now.timeIntervalSince(session.startDate))
                Text("Sleeping…")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("Since \(timeFormatter.string(from: session.startDate))")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("Elapsed \(formattedDuration(elapsed))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if let last = lastCompletedSession, let endDate = last.endDate {
                Text("Baby is awake")
                    .font(.title2.weight(.semibold))
                Text("Last nap ended at \(timeFormatter.string(from: endDate))")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            } else {
                Text("Ready for the next nap")
                    .font(.title2.weight(.semibold))
                Text("Tap start to begin tracking")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .glassBackground(cornerRadius: 28)
    }

    private var quickStats: some View {
        HStack(spacing: 20) {
            statCard(title: "Today", value: formattedDuration(todayDuration), subtitle: "Total sleep")
            statCard(title: "Sessions", value: "\(store.sessions(on: Date()).count)", subtitle: "Today")
        }
    }

    private var recentSessionsView: some View {
        let sessions = Array(store.sessions.prefix(3))
        return VStack(alignment: .leading, spacing: 16) {
            Text("Recent sessions")
                .font(.headline)
                .foregroundStyle(.secondary)
            if sessions.isEmpty {
                Text("No sessions yet. Start tracking to build history.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .glassBackground(cornerRadius: 24)
            } else {
                VStack(spacing: 12) {
                    ForEach(sessions, id: \.objectID) { session in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(session.formattedTimeRange)
                                .font(.headline)
                            Text(session.isActive ? "In progress" : session.formattedDuration)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .glassBackground(cornerRadius: 24)
                    }
                }
            }
        }
    }

    private var manualEntryButton: some View {
        Button {
            showManualEntry = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(BabyPalette.deepSage)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Add manually")
                        .font(.headline)
                    Text("Log a past sleep session")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()
            .glassBackground(cornerRadius: 24)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func statCard(title: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.weight(.bold))
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .glassBackground(cornerRadius: 24)
    }

    private func toggleSleepState() {
        if isSleeping {
            store.stopSession()
        } else {
            store.startSession()
        }
        store.fetchSessions()
    }

    private func startGlow() {
        withAnimation(.easeInOut(duration: 1.6)) {
            animateGlow = true
        }
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = duration >= 3600 ? [.hour, .minute] : [.minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0m"
    }
}

#Preview {
    ContentView()
        .environmentObject(SleepStore(context: PersistenceController.shared.container.viewContext))
}
