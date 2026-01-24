import SwiftUI

/// Full-screen player for sleep content (yoga nidra, stories, meditations, etc.)
struct SleepContentPlayerView: View {
    let content: SleepContent
    let onDismiss: () -> Void

    @Environment(SleepContentPlayerService.self) private var playerService
    @Environment(StoryProgressService.self) private var progressService
    @Environment(AppearanceService.self) private var appearanceService

    @State private var sliderValue: Double = 0
    @State private var isSliderEditing = false
    @State private var showTimerSheet = false
    @State private var dragOffset: CGFloat = 0

    private var categoryColor: Color {
        content.contentType.color
    }

    private var progress: Double {
        guard playerService.duration > 0 else { return 0 }
        return playerService.currentTime / playerService.duration
    }

    private var currentTimeFormatted: String {
        formatTime(isSliderEditing ? sliderValue * playerService.duration : playerService.currentTime)
    }

    private var remainingTimeFormatted: String {
        let remaining = playerService.duration - (isSliderEditing ? sliderValue * playerService.duration : playerService.currentTime)
        return "-" + formatTime(remaining)
    }

    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient

            // Content
            VStack(spacing: 0) {
                // Header with close button
                header

                Spacer()

                // Content info
                contentInfo

                Spacer()

                // Player controls
                if content.isAvailable {
                    playerControls
                } else {
                    comingSoonMessage
                }

                Spacer()
                    .frame(height: 50)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            playerService.setProgressService(progressService)
            if content.isAvailable {
                playerService.play(content: content)
            }
        }
        .onDisappear {
            // Progress is saved automatically by the service
        }
        .onChange(of: playerService.currentTime) { _, newValue in
            if !isSliderEditing {
                sliderValue = playerService.duration > 0 ? newValue / playerService.duration : 0
            }
        }
        .sheet(isPresented: $showTimerSheet) {
            SleepContentTimerSheet(
                contentDuration: playerService.duration,
                currentTime: playerService.currentTime,
                onTimerSelected: { minutes in
                    playerService.startSleepTimer(minutes: minutes)
                },
                onTimerCancelled: {
                    playerService.cancelSleepTimer()
                },
                isTimerActive: playerService.isTimerActive
            )
        }
        // Interactive swipe-to-minimize gesture
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Only allow downward drag
                    if value.translation.height > 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    // If dragged more than 150 points, dismiss to mini player
                    if value.translation.height > 150 {
                        withAnimation(.spring(response: 0.3)) {
                            dragOffset = UIScreen.main.bounds.height
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            onDismiss()
                        }
                    } else {
                        // Snap back
                        withAnimation(.spring(response: 0.3)) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .animation(.interactiveSpring(), value: dragOffset)
    }

    // MARK: - Background Gradient

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                categoryColor.opacity(0.8),
                categoryColor.opacity(0.4),
                Color(.systemBackground).opacity(0.95),
                Color(.systemBackground)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: {
                    // Don't stop playback - just minimize to mini player
                    onDismiss()
                }) {
                    Image(systemName: "chevron.down")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }

                Spacer()

                // Content type badge
                HStack(spacing: 6) {
                    Image(systemName: content.contentType.icon)
                        .font(.caption)
                    Text(content.contentType.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.2))
                .clipShape(Capsule())

                Spacer()

                // Timer button
                Button(action: {
                    showTimerSheet = true
                }) {
                    Image(systemName: playerService.isTimerActive ? "clock.fill" : "clock")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(playerService.isTimerActive ? .purple : .white)
                        .frame(width: 44, height: 44)
                        .background(playerService.isTimerActive ? Color.white : Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }

            // Timer countdown display
            if playerService.isTimerActive {
                HStack(spacing: 6) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.caption)
                    Text("\(playerService.timerRemainingFormatted) remaining")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.purple.opacity(0.6))
                .clipShape(Capsule())
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Content Info

    private var contentInfo: some View {
        VStack(spacing: 24) {
            // Cover art placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [categoryColor.opacity(0.6), categoryColor.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 240, height: 240)
                    .shadow(color: categoryColor.opacity(0.3), radius: 20, x: 0, y: 10)

                Image(systemName: content.contentType.icon)
                    .font(.system(size: 80))
                    .foregroundColor(.white.opacity(0.8))
            }

            // Title and narrator
            VStack(spacing: 8) {
                Text(content.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text(content.narrator)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(content.formattedDuration)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Player Controls

    private var playerControls: some View {
        VStack(spacing: 24) {
            // Progress slider
            VStack(spacing: 8) {
                Slider(
                    value: $sliderValue,
                    in: 0...1,
                    onEditingChanged: { editing in
                        isSliderEditing = editing
                        if !editing {
                            playerService.seek(to: sliderValue * playerService.duration)
                        }
                    }
                )
                .tint(categoryColor)

                // Time labels
                HStack {
                    Text(currentTimeFormatted)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .monospacedDigit()

                    Spacer()

                    Text(remainingTimeFormatted)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
            }

            // Playback buttons
            HStack(spacing: 40) {
                // Skip backward 15s
                Button(action: {
                    playerService.skipBackward()
                }) {
                    ZStack {
                        Image(systemName: "gobackward.15")
                            .font(.title)
                            .foregroundColor(.primary)
                    }
                    .frame(width: 60, height: 60)
                }

                // Play/Pause
                Button(action: {
                    if playerService.isPlaying {
                        playerService.pause()
                    } else {
                        if playerService.currentContent == nil {
                            playerService.play(content: content)
                        } else {
                            playerService.resume()
                        }
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(categoryColor)
                            .frame(width: 72, height: 72)
                            .shadow(color: categoryColor.opacity(0.4), radius: 10, x: 0, y: 5)

                        Image(systemName: playerService.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .offset(x: playerService.isPlaying ? 0 : 2)
                    }
                }

                // Skip forward 15s
                Button(action: {
                    playerService.skipForward()
                }) {
                    ZStack {
                        Image(systemName: "goforward.15")
                            .font(.title)
                            .foregroundColor(.primary)
                    }
                    .frame(width: 60, height: 60)
                }
            }
        }
    }

    // MARK: - Coming Soon Message

    private var comingSoonMessage: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.checkmark")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("Coming Soon")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text("This content is not yet available.\nCheck back soon!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }

    // MARK: - Helpers

    private func formatTime(_ time: TimeInterval) -> String {
        let totalSeconds = Int(max(0, time))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Preview

#Preview("Playing") {
    SleepContentPlayerView(
        content: SleepContent(
            id: "preview-1",
            title: "Deep Rest Yoga Nidra for Sleep",
            narrator: "Sarah Williams",
            duration: 600,
            contentType: .yogaNidra,
            description: "A deeply relaxing practice for peaceful sleep",
            audioFileName: "yoga_nidra_sleep_10min.mp3"
        ),
        onDismiss: {}
    )
    .environment(SleepContentPlayerService())
    .environment(StoryProgressService())
    .environment(AppearanceService())
    .preferredColorScheme(.dark)
}

#Preview("Coming Soon") {
    SleepContentPlayerView(
        content: SleepContent(
            id: "preview-2",
            title: "The Dream Garden",
            narrator: "James Cooper",
            duration: 1800,
            contentType: .sleepStory,
            description: "A peaceful journey through dreams",
            audioFileName: nil
        ),
        onDismiss: {}
    )
    .environment(SleepContentPlayerService())
    .environment(StoryProgressService())
    .environment(AppearanceService())
    .preferredColorScheme(.dark)
}
