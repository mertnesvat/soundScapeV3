import SwiftUI

struct SleepTimerView: View {
    @Environment(SleepTimerService.self) private var timerService
    @Environment(\.dismiss) private var dismiss

    @State private var selectedMinutes: Int = 30

    private static let presetMinutes: [Int] = [15, 30, 45, 60, 120]

    var body: some View {
        NavigationStack {
            VStack(spacing: 48) {
                Spacer(minLength: 0)

                countdownLabel

                presetChips

                startStopButton

                Spacer(minLength: 0)
            }
            .padding(.horizontal, DesignTokens.padding.edges)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DesignTokens.surface.ignoresSafeArea())
            .navigationTitle(LocalizedStringKey("Sleep Timer"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Countdown

    private var countdownLabel: some View {
        Text(displayedCountdown)
            .font(.system(size: 88, weight: DesignTokens.font.display, design: .rounded))
            .monospacedDigit()
            .foregroundColor(.primary)
            .contentTransition(.numericText())
            .animation(.linear(duration: 0.2), value: displayedCountdown)
    }

    private var displayedCountdown: String {
        if timerService.isActive {
            return timerService.remainingTimeFormatted
        }
        return formatted(minutes: selectedMinutes)
    }

    private func formatted(minutes: Int) -> String {
        String(format: "%02d:%02d", minutes, 0)
    }

    // MARK: - Preset chips

    private var presetChips: some View {
        HStack(spacing: 8) {
            ForEach(Self.presetMinutes, id: \.self) { minutes in
                presetChip(minutes: minutes)
            }
        }
    }

    private func presetChip(minutes: Int) -> some View {
        let isSelected = !timerService.isActive && selectedMinutes == minutes
        return Button {
            selectedMinutes = minutes
        } label: {
            Text(label(for: minutes))
                .font(.subheadline.weight(DesignTokens.font.body))
                .foregroundStyle(isSelected ? Color.white : Color.primary.opacity(0.85))
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.padding.compact)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.radius.button, style: .continuous)
                        .fill(isSelected ? DesignTokens.accent : Color.white.opacity(0.06))
                )
        }
        .buttonStyle(.plain)
        .disabled(timerService.isActive)
    }

    private func label(for minutes: Int) -> String {
        switch minutes {
        case 60: return String(localized: "1h")
        case 120: return String(localized: "2h")
        default: return "\(minutes)m"
        }
    }

    // MARK: - Start / Stop

    private var startStopButton: some View {
        Button {
            if timerService.isActive {
                timerService.cancel()
            } else {
                timerService.start(minutes: selectedMinutes)
            }
        } label: {
            Text(timerService.isActive
                 ? LocalizedStringKey("Stop")
                 : LocalizedStringKey("Start"))
                .font(.headline.weight(DesignTokens.font.header))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.padding.standard)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.radius.button, style: .continuous)
                        .fill(DesignTokens.accent)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SleepTimerView()
        .environment(SleepTimerService(audioEngine: AudioEngine()))
        .preferredColorScheme(.dark)
}
