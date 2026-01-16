import SwiftUI

struct NowPlayingBarView: View {
    @Environment(AudioEngine.self) private var audioEngine
    @State private var showMixer = false
    @State private var showTimer = false

    var body: some View {
        if !audioEngine.activeSounds.isEmpty {
            HStack(spacing: 16) {
                // Sound count and tap area
                Button(action: { showMixer = true }) {
                    HStack(spacing: 12) {
                        // Animated waveform indicator
                        WaveformIndicator(isAnimating: audioEngine.isAnyPlaying)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(audioEngine.activeSounds.count) sound\(audioEngine.activeSounds.count == 1 ? "" : "s") playing")
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
                    Image(systemName: "timer")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }

                // Play/Pause button
                Button(action: {
                    if audioEngine.isAnyPlaying {
                        audioEngine.pauseAll()
                    } else {
                        audioEngine.resumeAll()
                    }
                }) {
                    Image(systemName: audioEngine.isAnyPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title)
                        .foregroundColor(.purple)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .shadow(color: .black.opacity(0.3), radius: 10, y: -5)
            )
            .padding(.horizontal, 16)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .sheet(isPresented: $showMixer) {
                MixerView()
            }
            .sheet(isPresented: $showTimer) {
                // Timer placeholder - will be replaced in Feature 6
                NavigationStack {
                    ContentUnavailableView(
                        "Sleep Timer",
                        systemImage: "timer",
                        description: Text("Coming soon")
                    )
                    .navigationTitle("Timer")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showTimer = false }
                        }
                    }
                }
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
                        isAnimating ?
                            .easeInOut(duration: 0.4)
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
    NowPlayingBarView()
        .environment(AudioEngine())
        .preferredColorScheme(.dark)
}
