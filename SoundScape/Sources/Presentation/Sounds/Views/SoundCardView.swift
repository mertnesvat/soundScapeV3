import SwiftUI

struct SoundCardView: View {
    let sound: Sound
    let isPlaying: Bool
    let isFavorite: Bool
    let onTogglePlay: () -> Void
    let onToggleFavorite: () -> Void

    @State private var heartScale: CGFloat = 1.0

    private var categoryColor: Color {
        switch sound.category {
        case .noise: return .purple
        case .nature: return .green
        case .weather: return .blue
        case .fire: return .orange
        case .music: return .pink
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
            onTogglePlay: {},
            onToggleFavorite: {}
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
            onTogglePlay: {},
            onToggleFavorite: {}
        )
    }
    .padding()
    .preferredColorScheme(.dark)
    .background(Color(.systemBackground))
}
