import SwiftUI

struct SoundCardView: View {
    let sound: Sound
    let isPlaying: Bool
    let isFavorite: Bool
    let isLocked: Bool
    var index: Int = 1
    let onTogglePlay: () -> Void
    let onToggleFavorite: () -> Void
    let onLockedTap: () -> Void

    @State private var heartScale: CGFloat = 1.0

    private var accentColor: Color {
        isPlaying ? Tokens.colorOrange : Tokens.colorPeach
    }

    private var numeralText: String {
        String(format: "%02d", max(0, index))
    }

    private var categoryLabel: String {
        sound.category.rawValue.uppercased()
    }

    var body: some View {
        Button(action: onTogglePlay) {
            HStack(spacing: 0) {
                // Saturated accent bar (orange when active, peach otherwise)
                Rectangle()
                    .fill(accentColor)
                    .frame(width: 6)

                VStack(alignment: .leading, spacing: 8) {
                    // Top-left two-digit zero-padded numeral
                    Text(numeralText)
                        .font(.system(size: Tokens.displayNumeralSize,
                                      weight: .black,
                                      design: .default))
                        .foregroundColor(Tokens.colorInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    // Sound name: SF Pro Display bold 18pt
                    Text(sound.name)
                        .font(.system(size: 18, weight: .bold, design: .default))
                        .foregroundColor(Tokens.colorInk)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    // Category microcopy: SF Pro Text regular 12pt at 60% opacity
                    Text(categoryLabel)
                        .font(.system(size: 12, weight: .regular, design: .default))
                        .tracking(1.2)
                        .foregroundColor(Tokens.colorInk.opacity(0.6))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(
                RoundedRectangle(cornerRadius: Tokens.radiusTile, style: .continuous)
                    .fill(Tokens.colorCream)
            )
            .overlay(alignment: .bottom) {
                // Single 1pt hairline divider at the row bottom
                Rectangle()
                    .fill(Tokens.colorInk.opacity(0.08))
                    .frame(height: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: Tokens.radiusTile, style: .continuous))
        }
        .buttonStyle(EditorialTilePressStyle())
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
                    .foregroundColor(isFavorite ? Tokens.colorOrange : Tokens.colorInk.opacity(0.4))
                    .font(.system(size: 18, weight: .semibold))
                    .scaleEffect(heartScale)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
        }
    }
}

/// Editorial tile press style — applies a tactile press scale and nothing else.
private struct EditorialTilePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        return configuration.label
            .scaleEffect(isPressed ? 0.97 : 1)
            .animation(Tokens.tactilePress, value: isPressed)
    }
}

#Preview {
    VStack(spacing: 12) {
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
            index: 1,
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
            index: 12,
            onTogglePlay: {},
            onToggleFavorite: {},
            onLockedTap: {}
        )
    }
    .padding()
    .background(Tokens.colorCream.opacity(0.5))
}
