import SwiftUI

struct StoryPlayerView: View {
    @Environment(StoryProgressService.self) private var progressService
    @Environment(\.dismiss) private var dismiss

    let story: Story

    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    @State private var timer: Timer?

    private var gradientColors: [Color] {
        switch story.category {
        case .fiction:
            return [.indigo, .purple]
        case .nature:
            return [.green, .teal]
        case .meditation:
            return [.purple, .pink]
        case .asmr:
            return [.cyan, .blue]
        }
    }

    private var progressFraction: Double {
        guard story.duration > 0 else { return 0 }
        return currentTime / story.duration
    }

    private var remainingTimeText: String {
        let remaining = max(story.duration - currentTime, 0)
        let minutes = Int(remaining / 60)
        let seconds = Int(remaining.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d remaining", minutes, seconds)
    }

    private var currentTimeText: String {
        let minutes = Int(currentTime / 60)
        let seconds = Int(currentTime.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var durationText: String {
        let minutes = Int(story.duration / 60)
        let seconds = Int(story.duration.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: gradientColors.map { $0.opacity(0.3) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Cover art placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 280, height: 280)
                        .shadow(color: gradientColors[0].opacity(0.5), radius: 20, y: 10)

                    Image(systemName: story.category.icon)
                        .font(.system(size: 80))
                        .foregroundColor(.white.opacity(0.8))
                }

                // Story info
                VStack(spacing: 8) {
                    Text(story.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text(story.narrator)
                        .font(.title3)
                        .foregroundColor(.secondary)

                    Text(story.category.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color(.systemGray5))
                        )
                }
                .padding(.horizontal)

                Spacer()

                // Progress section
                VStack(spacing: 8) {
                    // Progress slider
                    Slider(value: $currentTime, in: 0...story.duration) { editing in
                        if !editing {
                            progressService.setProgress(currentTime, for: story.id)
                        }
                    }
                    .tint(gradientColors[0])

                    // Time labels
                    HStack {
                        Text(currentTimeText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(durationText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 24)

                // Playback controls
                HStack(spacing: 40) {
                    // Skip back 15s
                    Button {
                        skipBackward()
                    } label: {
                        Image(systemName: "gobackward.15")
                            .font(.system(size: 32))
                            .foregroundColor(.primary)
                    }

                    // Play/Pause
                    Button {
                        togglePlayback()
                    } label: {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 72))
                            .foregroundColor(gradientColors[0])
                    }

                    // Skip forward 15s
                    Button {
                        skipForward()
                    } label: {
                        Image(systemName: "goforward.15")
                            .font(.system(size: 32))
                            .foregroundColor(.primary)
                    }
                }

                // Coming soon note (since no actual audio)
                Text("Audio coming soon - progress simulation active")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)

                Spacer()
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            currentTime = progressService.getProgress(for: story.id)
        }
        .onDisappear {
            stopSimulation()
            progressService.setProgress(currentTime, for: story.id)
        }
    }

    private func togglePlayback() {
        isPlaying.toggle()
        if isPlaying {
            startSimulation()
        } else {
            stopSimulation()
        }
    }

    private func startSimulation() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if currentTime < story.duration {
                currentTime += 1
            } else {
                stopSimulation()
                isPlaying = false
            }
        }
    }

    private func stopSimulation() {
        timer?.invalidate()
        timer = nil
        progressService.setProgress(currentTime, for: story.id)
    }

    private func skipBackward() {
        currentTime = max(currentTime - 15, 0)
        progressService.setProgress(currentTime, for: story.id)
    }

    private func skipForward() {
        currentTime = min(currentTime + 15, story.duration)
        progressService.setProgress(currentTime, for: story.id)
    }
}

#Preview {
    NavigationStack {
        StoryPlayerView(story: LocalStoryDataSource.stories[0])
    }
    .environment(StoryProgressService())
    .preferredColorScheme(.dark)
}
