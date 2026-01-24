import SwiftUI

/// Timer option for sleep content playback
struct SleepContentTimerOption: Identifiable {
    let id = UUID()
    let minutes: Int
    let label: String
    let isEndOfContent: Bool

    static func presets(contentDuration: TimeInterval) -> [SleepContentTimerOption] {
        var options = [
            SleepContentTimerOption(minutes: 5, label: "5 min", isEndOfContent: false),
            SleepContentTimerOption(minutes: 10, label: "10 min", isEndOfContent: false),
            SleepContentTimerOption(minutes: 15, label: "15 min", isEndOfContent: false),
            SleepContentTimerOption(minutes: 30, label: "30 min", isEndOfContent: false),
            SleepContentTimerOption(minutes: 45, label: "45 min", isEndOfContent: false),
            SleepContentTimerOption(minutes: 60, label: "1 hour", isEndOfContent: false),
        ]

        // Add "End of Content" option if content has a duration
        if contentDuration > 0 {
            let remainingMinutes = Int(ceil(contentDuration / 60))
            options.append(SleepContentTimerOption(
                minutes: remainingMinutes,
                label: "End of Content",
                isEndOfContent: true
            ))
        }

        return options
    }
}

/// Bottom sheet for selecting sleep timer duration for wind down content
struct SleepContentTimerSheet: View {
    let contentDuration: TimeInterval
    let currentTime: TimeInterval
    let onTimerSelected: (Int) -> Void
    let onTimerCancelled: () -> Void
    let isTimerActive: Bool

    @Environment(\.dismiss) private var dismiss

    private var timerOptions: [SleepContentTimerOption] {
        let remainingDuration = max(0, contentDuration - currentTime)
        return SleepContentTimerOption.presets(contentDuration: remainingDuration)
    }

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header icon
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.purple.opacity(0.8))
                    .padding(.top, 8)

                if isTimerActive {
                    activeTimerView
                } else {
                    timerSelectionView
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .navigationTitle("Sleep Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Active Timer View

    private var activeTimerView: some View {
        VStack(spacing: 20) {
            Text("Timer Active")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Audio will fade out when timer ends")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: {
                onTimerCancelled()
                dismiss()
            }) {
                Label("Cancel Timer", systemImage: "xmark.circle")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .padding(.top, 8)
        }
    }

    // MARK: - Timer Selection View

    private var timerSelectionView: some View {
        VStack(spacing: 20) {
            Text("Set Sleep Timer")
                .font(.headline)
                .foregroundColor(.secondary)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(timerOptions) { option in
                    Button(action: {
                        onTimerSelected(option.minutes)
                        dismiss()
                    }) {
                        VStack(spacing: 6) {
                            if option.isEndOfContent {
                                Image(systemName: "flag.checkered")
                                    .font(.title3)
                            }
                            Text(option.label)
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(option.isEndOfContent ? Color.purple.opacity(0.15) : Color(.systemGray5))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(option.isEndOfContent ? Color.purple.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(option.isEndOfContent ? .purple : .primary)
                }
            }

            Text("Audio will gradually fade out over 30 seconds when the timer ends")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

// MARK: - Preview

#Preview("Timer Selection") {
    SleepContentTimerSheet(
        contentDuration: 600,
        currentTime: 120,
        onTimerSelected: { minutes in print("Selected: \(minutes) min") },
        onTimerCancelled: {},
        isTimerActive: false
    )
}

#Preview("Timer Active") {
    SleepContentTimerSheet(
        contentDuration: 600,
        currentTime: 120,
        onTimerSelected: { _ in },
        onTimerCancelled: { print("Cancelled") },
        isTimerActive: true
    )
}
