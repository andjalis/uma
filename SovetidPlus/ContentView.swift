import Combine
import CoreData
import SwiftUI

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
            colors = [Color.black, Color.blue.opacity(0.45)]
        } else {
            colors = [Color.cyan.opacity(0.35), Color(.systemBackground)]
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
            ZStack {
                gradientBackground
                    .ignoresSafeArea()

                VStack(spacing: 28) {
                    Spacer()

                    sleepButton

                    statusView

                    quickStats

                    recentSessionsView

                    Spacer()

                    manualEntryButton
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .padding(.top, 24)
            }
            .navigationTitle("Baby Sleep")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SleepCalendarView()
                    } label: {
                        Image(systemName: "calendar")
                            .font(.title3)
                            .foregroundStyle(.primary)
                            .padding(12)
                            .background(BlurView(style: .systemThinMaterial))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
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
    }

    private var sleepButton: some View {
        Button(action: toggleSleepState) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isSleeping ? [Color.purple.opacity(0.9), Color.indigo] : [Color.cyan, Color.blue.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 220, height: 220)
                    .shadow(color: (isSleeping ? Color.purple : Color.cyan).opacity(0.4), radius: 30, x: 0, y: 18)

                if isSleeping {
                    Circle()
                        .stroke(Color.purple.opacity(0.4), lineWidth: 12)
                        .frame(width: 260, height: 260)
                        .scaleEffect(animateGlow ? 1.15 : 0.95)
                        .opacity(animateGlow ? 0.5 : 0.15)
                        .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: animateGlow)
                }

                VStack(spacing: 12) {
                    Image(systemName: isSleeping ? "pause.fill" : "play.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(isSleeping ? "Stop" : "Start")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Sleep")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
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
                    .foregroundStyle(Color.cyan)
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
