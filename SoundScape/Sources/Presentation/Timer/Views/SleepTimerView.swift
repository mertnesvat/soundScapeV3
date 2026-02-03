import SwiftUI

struct SleepTimerView: View {
    @Environment(SleepTimerService.self) private var timerService
    @Environment(\.dismiss) private var dismiss

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                if timerService.isActive {
                    activeTimerView
                } else {
                    presetSelectionView
                }

                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle(LocalizedStringKey("Sleep Timer"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Active Timer View

    private var activeTimerView: some View {
        VStack(spacing: 24) {
            Text(timerService.remainingTimeFormatted)
                .font(.system(size: 72, weight: .thin, design: .rounded))
                .monospacedDigit()
                .foregroundColor(.primary)

            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: timerService.progress)
                    .stroke(
                        Color.purple,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timerService.progress)

                VStack(spacing: 4) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.purple)

                    if timerService.remainingSeconds <= 30 {
                        Text(LocalizedStringKey("Fading out..."))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(width: 200, height: 200)

            Button(action: {
                timerService.cancel()
            }) {
                Label(LocalizedStringKey("Cancel Timer"), systemImage: "xmark.circle")
                    .font(.headline)
            }
            .foregroundColor(.red)
            .buttonStyle(.bordered)
            .tint(.red)
        }
    }

    // MARK: - Preset Selection View

    private var presetSelectionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "moon.zzz")
                .font(.system(size: 60))
                .foregroundColor(.purple.opacity(0.7))

            Text(LocalizedStringKey("Set Sleep Timer"))
                .font(.headline)
                .foregroundColor(.secondary)

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(SleepTimerPreset.presets) { preset in
                    Button(action: {
                        timerService.start(minutes: preset.minutes)
                    }) {
                        Text(preset.localizedLabel)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color(.systemGray5))
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)

            Text(LocalizedStringKey("Audio will gradually fade out during the last 30 seconds"))
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}

#Preview {
    SleepTimerView()
        .environment(SleepTimerService(audioEngine: AudioEngine()))
        .preferredColorScheme(.dark)
}
