import SwiftUI

struct ManualEntryView: View {
    @Environment(\.dismiss) private var dismiss
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
                    Text("Start time")
                        .font(.headline)
                        .foregroundStyle(.primary.opacity(0.8))
                    DatePicker("Start", selection: $startDate, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
                .padding()
                .glassBackground()

                VStack(alignment: .leading, spacing: 12) {
                    Text("End time")
                        .font(.headline)
                        .foregroundStyle(.primary.opacity(0.8))
                    DatePicker("End", selection: $endDate, in: startDate...Date(), displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
                .padding()
                .glassBackground()

                if showValidationError {
                    Text("End time must be after start time.")
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
                    Text("Save Session")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(colors: [Color.indigo, Color.blue.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .foregroundStyle(.white)
                        .shadow(color: .blue.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(24)
            .background(LinearGradient(colors: [Color(.secondarySystemBackground), Color(.systemBackground)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea())
            .navigationTitle("Add Sleep")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
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
}
