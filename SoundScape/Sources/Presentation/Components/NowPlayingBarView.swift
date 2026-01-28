import SwiftUI

struct NowPlayingBarView: View {
    @Environment(AudioEngine.self) private var audioEngine
    @Environment(SleepTimerService.self) private var timerService
    @Environment(AppearanceService.self) private var appearanceService
    @Binding var showMixer: Bool
    @State private var showTimer = false

    private var barBackgroundColor: Color {
        appearanceService.isOLEDModeEnabled
            ? Color(.systemGray6).opacity(0.25)
            : Color(.systemGray6)
    }

    private var barShadowColor: Color {
        appearanceService.isOLEDModeEnabled
            ? Color.purple.opacity(0.4)
            : Color.black.opacity(0.3)
    }

    var body: some View {
        if !audioEngine.activeSounds.isEmpty {
            HStack(spacing: 16) {
                // Sound count and tap area
                Button(action: { showMixer = true }) {
                    HStack(spacing: 12) {
                        // Animated waveform indicator
                        WaveformIndicator(isAnimating: audioEngine.isAnyPlaying)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(
                                "\(audioEngine.activeSounds.count) sound\(audioEngine.activeSounds.count == 1 ? "" : "s") playing"
                            )
                            .font(.subheadline)
                            .fontWeight(.medium)

                            Text("Tap to mix")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                // Timer button
                Button(action: { showTimer = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: timerService.isActive ? "timer.circle.fill" : "timer")
                            .font(.title3)
                            .foregroundColor(timerService.isActive ? .purple : .secondary)

                        if timerService.isActive {
                            Text(timerService.remainingTimeFormatted)
                                .font(.caption)
                                .monospacedDigit()
                                .foregroundColor(.purple)
                        }
                    }
                }

                // Play/Pause button
                Button(action: {
                    if audioEngine.isAnyPlaying {
                        audioEngine.pauseAll()
                    } else {
                        audioEngine.resumeAll()
                    }
                }) {
                    Image(
                        systemName: audioEngine.isAnyPlaying
                            ? "pause.circle.fill" : "play.circle.fill"
                    )
                    .font(.title)
                    .foregroundColor(.purple)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(barBackgroundColor)
                    .shadow(color: barShadowColor, radius: 10, y: -5)
            )
            .padding(.horizontal, 16)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .sheet(isPresented: $showMixer) {
                MixerView()
            }
            .sheet(isPresented: $showTimer) {
                SleepTimerView()
            }
        }
    }
}

// Animated waveform bars
struct WaveformIndicator: View {
    let isAnimating: Bool

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.purple)
                    .frame(width: 3, height: isAnimating ? 20 : 8)
                    .animation(
                        isAnimating
                            ? .easeInOut(duration: 0.4)
                                .repeatForever()
                                .delay(Double(index) * 0.1) : .default,
                        value: isAnimating
                    )
            }
        }
        .frame(width: 20, height: 20)
    }
}

#Preview {
    @Previewable @State var showMixer = false
    let audioEngine = AudioEngine()
    return NowPlayingBarView(showMixer: $showMixer)
        .environment(audioEngine)
        .environment(SleepTimerService(audioEngine: audioEngine))
        .environment(AppearanceService())
        .preferredColorScheme(.dark)
}
