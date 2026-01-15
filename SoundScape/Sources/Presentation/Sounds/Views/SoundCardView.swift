import SwiftUI

struct SoundCardView: View {
    let sound: Sound
    let isPlaying: Bool
    let onTogglePlay: () -> Void

    private var categoryColor: Color {
        switch sound.category {
        case .noise: return .purple
        case .nature: return .green
        case .weather: return .blue
        case .fire: return .orange
        }
    }

    var body: some View {
        Button(action: onTogglePlay) {
            VStack(spacing: 12) {
                // Icon with glow effect when playing
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.2))
                        .frame(width: 60, height: 60)

                    if isPlaying {
                        Circle()
                            .fill(categoryColor.opacity(0.3))
                            .frame(width: 70, height: 70)
                            .blur(radius: 10)
                    }

                    Image(systemName: sound.category.icon)
                        .font(.system(size: 24))
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

                // Category label
                Text(sound.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Play/Pause indicator
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(isPlaying ? categoryColor : .gray)
                    .symbolEffect(.bounce, value: isPlaying)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .shadow(
                        color: isPlaying ? categoryColor.opacity(0.4) : .clear,
                        radius: isPlaying ? 12 : 0
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isPlaying ? categoryColor.opacity(0.5) : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.3), value: isPlaying)
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
            onTogglePlay: {}
        )

        SoundCardView(
            sound: Sound(
                id: "fire",
                name: "Campfire",
                category: .fire,
                fileName: "campfire.mp3"
            ),
            isPlaying: true,
            onTogglePlay: {}
        )
    }
    .padding()
    .preferredColorScheme(.dark)
    .background(Color(.systemBackground))
}
