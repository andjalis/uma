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

    private var solidBackground: Color {
        colorScheme == .dark ? AppColors.backgroundDark : AppColors.backgroundLight
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "da_DK")
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
                    solidBackground
                        .ignoresSafeArea()
                    heroHighlight

                    VStack(spacing: 24) {
                        topBar
                        Spacer(minLength: 12)
                        sleepButton(size: buttonDiameter)
                        statusView
                        quickStats
                        recentSessionsView
                        Spacer(minLength: 20)
                        manualEntryButton
                    }
                    .padding(.horizontal, 28)
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
                    .fill(buttonColor(isSleeping: isSleeping))
                    .frame(width: size, height: size)
                    .shadow(color: buttonShadow(isSleeping: isSleeping), radius: 34, x: 0, y: 26)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.18), lineWidth: 1.2)
                    )

                if isSleeping {
                    Circle()
                        .stroke(ringColor(isSleeping: isSleeping), lineWidth: 12)
                        .frame(width: size + 44, height: size + 44)
                        .scaleEffect(animateGlow ? 1.12 : 0.94)
                        .opacity(animateGlow ? 0.55 : 0.25)
                        .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: animateGlow)
                }

                VStack(spacing: 14) {
                    Image(systemName: isSleeping ? "pause.fill" : "play.fill")
                        .font(.system(size: max(36, size * 0.16), weight: .semibold))
                        .foregroundStyle(Color.white)
                    Text(isSleeping ? "Pause lur" : "Start lur")
                        .font(.system(size: max(28, size * 0.12), weight: .bold))
                        .foregroundStyle(Color.white)
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(isSleeping ? "Stop lur" : "Start lur")
    }

    private var heroHighlight: some View {
        Circle()
            .fill(AppColors.buttonActive.opacity(0.18))
            .blur(radius: 120)
            .scaleEffect(1.4)
            .offset(x: -80, y: -120)
            .ignoresSafeArea()
    }

    private func buttonColor(isSleeping: Bool) -> Color {
        isSleeping ? AppColors.buttonActive : AppColors.buttonInactive
    }

    private func ringColor(isSleeping: Bool) -> Color {
        return isSleeping ? AppColors.buttonActive : AppColors.buttonInactive
    }

    private func buttonShadow(isSleeping: Bool) -> Color {
        let base = isSleeping ? AppColors.buttonActive : AppColors.buttonInactive
        return base.opacity(0.5)
    }

    private var topBar: some View {
        HStack {
            Spacer()
            NavigationLink {
                SleepCalendarView()
            } label: {
                Image(systemName: "calendar")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.white)
                    .padding(16)
                    .background(AppColors.accentSurface)
                    .clipShape(Circle())
                    .shadow(color: AppColors.accent.opacity(0.3), radius: 10, x: 0, y: 6)
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    private var statusView: some View {
        VStack(spacing: 8) {
            if let session = activeSession {
                let elapsed = max(0, now.timeIntervalSince(session.startDate))
                Text("Sover…")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("Siden \(timeFormatter.string(from: session.startDate))")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("Forløbet tid \(formattedDuration(elapsed))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if let last = lastCompletedSession, let endDate = last.endDate {
                Text("Baby er vågen")
                    .font(.title2.weight(.semibold))
                Text("Seneste lur sluttede kl. \(timeFormatter.string(from: endDate))")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            } else {
                Text("Klar til næste lur")
                    .font(.title2.weight(.semibold))
                Text("Tryk start for at begynde registreringen")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppColors.accentSurface.opacity(colorScheme == .dark ? 0.55 : 0.35))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var quickStats: some View {
        HStack(spacing: 20) {
            statCard(title: "I dag", value: formattedDuration(todayDuration), subtitle: "Samlet søvn")
            statCard(title: "Lure", value: "\(store.sessions(on: Date()).count)", subtitle: "I dag")
        }
    }

    private var recentSessionsView: some View {
        let sessions = Array(store.sessions.prefix(3))
        return VStack(alignment: .leading, spacing: 16) {
            Text("Seneste registreringer")
                .font(.headline)
                .foregroundStyle(.secondary)
            if sessions.isEmpty {
                Text("Ingen registreringer endnu. Start sporing for at opbygge historik.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(AppColors.accentSurface.opacity(colorScheme == .dark ? 0.55 : 0.35))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            } else {
                VStack(spacing: 12) {
                    ForEach(sessions, id: \.objectID) { session in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(session.formattedTimeRange)
                                .font(.headline)
                            Text(session.isActive ? "I gang" : session.formattedDuration)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(AppColors.accentSurface.opacity(colorScheme == .dark ? 0.55 : 0.35))
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

    private var manualEntryButton: some View {
        Button {
            showManualEntry = true
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.white)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tilføj manuelt")
                        .font(.headline)
                    Text("Registrer en tidligere lur")
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.85))
                }
                Spacer()
            }
            .padding()
            .background(AppColors.accentSurface)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: AppColors.accent.opacity(0.4), radius: 16, x: 0, y: 10)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func statCard(title: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.8))
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.white)
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(Color.white.opacity(0.85))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppColors.softCardSurface.opacity(colorScheme == .dark ? 0.8 : 0.9))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: AppColors.buttonInactive.opacity(0.25), radius: 12, x: 0, y: 8)
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
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.calendar?.locale = Locale(identifier: "da_DK")
        return formatter.string(from: duration) ?? "0 min"
    }
}

#Preview {
    ContentView()
        .environmentObject(SleepStore(context: PersistenceController.shared.container.viewContext))
}
