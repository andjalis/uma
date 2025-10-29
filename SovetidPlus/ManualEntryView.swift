import SwiftUI

struct ManualEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let onSave: (Date, Date) -> Bool

    @State private var startDate: Date
    @State private var endDate: Date
    @State private var showValidationError = false

    init(initialStart: Date = Date().addingTimeInterval(-3600), initialEnd: Date = Date(), onSave: @escaping (Date, Date) -> Bool) {
        self.onSave = onSave
        _startDate = State(initialValue: initialStart)
        _endDate = State(initialValue: initialEnd)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Starttid")
                        .font(.headline)
                        .foregroundStyle(.primary.opacity(0.85))
                    DatePicker("Starttid", selection: $startDate, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(AppColors.accentSurface.opacity(colorScheme == .dark ? 0.55 : 0.35))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("Sluttid")
                        .font(.headline)
                        .foregroundStyle(.primary.opacity(0.85))
                    DatePicker("Sluttid", selection: $endDate, in: startDate...Date(), displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(AppColors.accentSurface.opacity(colorScheme == .dark ? 0.55 : 0.35))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )

                if showValidationError {
                    Text("Sluttid skal være efter starttid.")
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .transition(.opacity)
                }

                Spacer()

                Button {
                    if onSave(startDate, endDate) {
                        dismiss()
                    } else {
                        withAnimation { showValidationError = true }
                    }
                } label: {
                    Text("Gem registrering")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.buttonActive)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .foregroundStyle(.white)
                        .shadow(color: AppColors.buttonActive.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(24)
            .background(backgroundColor().ignoresSafeArea())
            .navigationTitle("Tilføj søvn")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Annuller") { dismiss() } } }
        }
        .onChange(of: startDate) { newValue in
            if endDate < newValue {
                endDate = newValue.addingTimeInterval(1800)
            }
            showValidationError = false
        }
        .onChange(of: endDate) { _ in
            showValidationError = false
        }
    }

    private func backgroundColor() -> Color {
        if colorScheme == .dark {
            return AppColors.backgroundDark
        } else {
            return AppColors.backgroundLight
        }
    }
}
