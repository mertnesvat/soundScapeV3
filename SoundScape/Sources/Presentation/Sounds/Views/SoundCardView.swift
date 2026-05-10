import SwiftUI

struct SoundCardView: View {
    let sound: Sound
    let isPlaying: Bool
    let isFavorite: Bool
    let isLocked: Bool
    let onTogglePlay: () -> Void
    let onToggleFavorite: () -> Void
    let onLockedTap: () -> Void

    @State private var heartScale: CGFloat = 1.0

    private var categoryColor: Color {
        DesignTokens.categoryColor(for: sound.category)
    }

    var body: some View {
        Button(action: onTogglePlay) {
            Text(sound.name)
                .font(.subheadline)
                .fontWeight(DesignTokens.font.body)
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(DesignTokens.padding.compact)
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.radius.card)
                        .fill(DesignTokens.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.radius.card)
                        .stroke(categoryColor.opacity(0.3), lineWidth: 1)
                )
                .shadow(
                    color: isPlaying ? categoryColor.opacity(DesignTokens.shadow.opacity) : .clear,
                    radius: isPlaying ? DesignTokens.shadow.minRadius : 0
                )
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
                    .font(.footnote)
                    .scaleEffect(heartScale)
            }
            .padding(DesignTokens.padding.compact)
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
    .background(DesignTokens.surface)
}
