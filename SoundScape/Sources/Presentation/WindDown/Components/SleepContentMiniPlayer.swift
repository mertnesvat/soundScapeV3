import SwiftUI

/// Mini player bar for sleep content that appears when the full player is dismissed
/// Similar to music app mini players - shows current track with play/pause and progress
struct SleepContentMiniPlayer: View {
    let onTap: () -> Void

    @Environment(SleepContentPlayerService.self) private var playerService
    @Environment(AppearanceService.self) private var appearanceService

    private var content: SleepContent? {
        playerService.currentContent
    }

    private var progress: Double {
        guard playerService.duration > 0 else { return 0 }
        return playerService.currentTime / playerService.duration
    }

    private var barBackgroundColor: Color {
        appearanceService.isOLEDModeEnabled
            ? Color(.systemGray6).opacity(0.25)
            : Color(.systemGray6)
    }

    private var barShadowColor: Color {
        appearanceService.isOLEDModeEnabled
            ? (content?.contentType.color ?? .purple).opacity(0.4)
            : Color.black.opacity(0.3)
    }

    var body: some View {
        if let content = content {
            VStack(spacing: 0) {
                // Progress bar at top
                GeometryReader { geometry in
                    Rectangle()
                        .fill(content.contentType.color)
                        .frame(width: geometry.size.width * progress, height: 3)
                }
                .frame(height: 3)

                // Main content
                HStack(spacing: 12) {
                    // Tap area for expanding player
                    Button(action: onTap) {
                        HStack(spacing: 12) {
                            // Cover art or icon with animated indicator
                            ZStack {
                                if let coverName = content.coverImageName {
                                    // Use cover image
                                    Image(coverName)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 44, height: 44)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else {
                                    // Fallback to icon
                                    Circle()
                                        .fill(content.contentType.color.opacity(0.2))
                                        .frame(width: 44, height: 44)

                                    Image(systemName: content.contentType.icon)
                                        .font(.system(size: 18))
                                        .foregroundColor(content.contentType.color)
                                }

                                // Animated breathing indicator when playing
                                if playerService.isPlaying {
                                    RoundedRectangle(cornerRadius: content.coverImageName != nil ? 8 : 22)
                                        .stroke(content.contentType.color, lineWidth: 2)
                                        .frame(width: 44, height: 44)
                                        .scaleEffect(playerService.isPlaying ? 1.15 : 1.0)
                                        .opacity(playerService.isPlaying ? 0 : 1)
                                        .animation(
                                            .easeInOut(duration: 1.5)
                                            .repeatForever(autoreverses: true),
                                            value: playerService.isPlaying
                                        )
                                }
                            }

                            // Title and narrator
                            VStack(alignment: .leading, spacing: 2) {
                                Text(content.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)

                                HStack(spacing: 4) {
                                    Text(content.narrator)
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    if playerService.isTimerActive {
                                        Text("•")
                                            .foregroundColor(.secondary)

                                        Image(systemName: "moon.zzz")
                                            .font(.caption2)
                                            .foregroundColor(.purple)

                                        Text(playerService.timerRemainingFormatted)
                                            .font(.caption)
                                            .foregroundColor(.purple)
                                            .monospacedDigit()
                                    }
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // Play/Pause button
                    Button(action: {
                        if playerService.isPlaying {
                            playerService.pause()
                        } else {
                            playerService.resume()
                        }
                    }) {
                        Image(systemName: playerService.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(content.contentType.color)
                    }

                    // Close button
                    Button(action: {
                        playerService.stop()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(barBackgroundColor)
                    .shadow(color: barShadowColor, radius: 10, y: -5)
            )
            .padding(.horizontal, 16)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
        SleepContentMiniPlayer(onTap: {})
    }
    .environment(SleepContentPlayerService())
    .environment(AppearanceService())
    .preferredColorScheme(.dark)
}
