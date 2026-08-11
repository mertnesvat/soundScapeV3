import SwiftUI

struct SoundCardView: View {
    let sound: Sound
    let isPlaying: Bool
    let isFavorite: Bool
    let isLocked: Bool
    let onTogglePlay: () -> Void
    let onToggleFavorite: () -> Void
    let onLockedTap: () -> Void

    @Environment(AppearanceService.self) private var appearanceService
    @Environment(MotionService.self) private var motionService
    @State private var heartScale: CGFloat = 1.0

    private var categoryColor: Color {
        sound.category.swiftUIColor
    }

    private var cardBackgroundColor: Color {
        if appearanceService.isOLEDModeEnabled {
            return isPlaying
                ? Color(.systemGray6).opacity(0.15)
                : Color(.systemGray6).opacity(0.08)
        } else {
            return Color(.systemGray6)
        }
    }

    private var glowColor: Color {
        if isPlaying {
            return appearanceService.isOLEDModeEnabled
                ? categoryColor.opacity(0.6)
                : categoryColor.opacity(0.4)
        }
        return .clear
    }

    var body: some View {
        Button(action: onTogglePlay) {
            VStack(spacing: 10) {
                // Icon with glow effect when playing, mini visualization overlay
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.2))
                        .frame(width: 56, height: 56)

                    if isPlaying {
                        Circle()
                            .fill(categoryColor.opacity(0.3))
                            .frame(width: 66, height: 66)
                            .blur(radius: 10)

                        // Mini visualization when playing
                        MiniVisualizationView(sound: sound, volume: 0.7, size: 46)
                            .opacity(0.8)
                    }

                    Image(systemName: sound.category.icon)
                        .font(.system(size: 22))
                        .foregroundColor(categoryColor)
                }
                .animation(.easeInOut(duration: 0.3), value: isPlaying)

                // Sound name
                Text(sound.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(cardBackgroundColor)
                    .shadow(
                        color: glowColor,
                        radius: isPlaying ? (appearanceService.isOLEDModeEnabled ? 16 : 12) : 0
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isPlaying ? categoryColor.opacity(appearanceService.isOLEDModeEnabled ? 0.7 : 0.5) : Color.clear,
                        lineWidth: appearanceService.isOLEDModeEnabled ? 1 : 2
                    )
            )
            .reflectiveSheen(categoryColor: categoryColor, cornerRadius: 16)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.3), value: isPlaying)
        .premiumLocked(isLocked: isLocked, onTap: onLockedTap)
        .overlay(alignment: .topTrailing) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    heartScale = 1.3
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        heartScale = 1.0
                    }
                }
                onToggleFavorite()
            }) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .foregroundColor(isFavorite ? .red : .gray)
                    .font(.title3)
                    .scaleEffect(heartScale)
            }
            .padding(12)
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        SoundCardView(
            sound: Sound(
                id: "rain",
                name: "Rain Storm",
                category: .weather,
                fileName: "rain_storm.mp3"
            ),
            isPlaying: false,
            isFavorite: false,
            isLocked: true,
            onTogglePlay: {},
            onToggleFavorite: {},
            onLockedTap: {}
        )

        SoundCardView(
            sound: Sound(
                id: "fire",
                name: "Campfire",
                category: .fire,
                fileName: "campfire.mp3"
            ),
            isPlaying: true,
            isFavorite: true,
            isLocked: false,
            onTogglePlay: {},
            onToggleFavorite: {},
            onLockedTap: {}
        )
    }
    .padding()
    .preferredColorScheme(.dark)
    .background(Color(.systemBackground))
    .environment(AppearanceService())
    .environment(MotionService())
}
