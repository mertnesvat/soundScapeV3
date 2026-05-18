import SwiftUI

/// Editorial mixer row — cream canvas, oversized zero-padded numeral, bold
/// sound name, and an inline horizontal volume slider with an orange track-fill
/// and ink thumb. Replaces the legacy purple-tinted dark gradient row.
struct MixerSoundRowView: View {
    let activeSound: ActiveSound
    var index: Int = 1
    let onVolumeChange: (Float) -> Void
    let onRemove: () -> Void
    var onVolumeCommit: ((Float) -> Void)?

    @State private var volume: Float

    init(
        activeSound: ActiveSound,
        index: Int = 1,
        onVolumeChange: @escaping (Float) -> Void,
        onRemove: @escaping () -> Void,
        onVolumeCommit: ((Float) -> Void)? = nil
    ) {
        self.activeSound = activeSound
        self.index = index
        self.onVolumeChange = onVolumeChange
        self.onRemove = onRemove
        self.onVolumeCommit = onVolumeCommit
        self._volume = State(initialValue: activeSound.volume)
    }

    private var numeralText: String {
        String(format: "%02d", max(0, index))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 16) {
                // Left-side zero-padded numeral — 48pt black on cream.
                Text(numeralText)
                    .font(.system(size: 48, weight: .black, design: .default))
                    .foregroundColor(Tokens.colorInk)
                    .frame(width: 76, alignment: .leading)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                VStack(alignment: .leading, spacing: 8) {
                    // Sound name — 18pt bold ink.
                    Text(activeSound.sound.name)
                        .font(.system(size: 18, weight: .bold, design: .default))
                        .foregroundColor(Tokens.colorInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    // Editorial slider: orange track-fill, ink thumb.
                    EditorialVolumeSlider(value: $volume) { editing in
                        onVolumeChange(volume)
                        if !editing {
                            onVolumeCommit?(volume)
                        }
                    }
                    .frame(height: 22)
                    .accessibilityLabel(Text(activeSound.sound.name) + Text(" volume"))
                    .accessibilityValue("\(Int(volume * 100)) percent")
                }

                // Remove button — ink-outlined square chip; no red destructive tint.
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Tokens.colorInk)
                        .frame(width: 32, height: 32)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Tokens.colorInk, lineWidth: 1.5)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Remove \(activeSound.sound.name)"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: Tokens.editorialRowHeight, alignment: .center)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Tokens.colorCream)

            // 1pt hairline divider terminating the row.
            Rectangle()
                .fill(Tokens.colorInk.opacity(0.08))
                .frame(height: 1)
        }
    }
}

/// Custom horizontal slider that paints the active track-fill in
/// `Tokens.colorOrange` and the thumb in `Tokens.colorInk`, satisfying the
/// editorial spec the stock `Slider` cannot express via `.tint()` alone.
private struct EditorialVolumeSlider: View {
    @Binding var value: Float
    var onEditingChanged: ((Bool) -> Void)?

    private let trackHeight: CGFloat = 4
    private let thumbDiameter: CGFloat = 18

    @State private var isDragging = false

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let clamped = CGFloat(min(max(value, 0), 1))
            let thumbX = clamped * width

            ZStack(alignment: .leading) {
                // Inactive track — soft ink at 12% on cream.
                Capsule()
                    .fill(Tokens.colorInk.opacity(0.12))
                    .frame(height: trackHeight)

                // Active track-fill in editorial orange.
                Capsule()
                    .fill(Tokens.colorOrange)
                    .frame(width: max(0, thumbX), height: trackHeight)

                // Ink thumb.
                Circle()
                    .fill(Tokens.colorInk)
                    .frame(width: thumbDiameter, height: thumbDiameter)
                    .offset(x: thumbX - thumbDiameter / 2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        if !isDragging {
                            isDragging = true
                            onEditingChanged?(true)
                        }
                        let newValue = Float(min(max(drag.location.x / width, 0), 1))
                        value = newValue
                    }
                    .onEnded { _ in
                        isDragging = false
                        onEditingChanged?(false)
                    }
            )
        }
    }
}

#Preview {
    let sound = Sound(
        id: "test",
        name: "White Noise",
        category: .noise,
        fileName: "white_noise.mp3"
    )
    let activeSound = ActiveSound(
        id: "test",
        sound: sound,
        volume: 0.7,
        isPlaying: true
    )

    return VStack(spacing: 0) {
        MixerSoundRowView(
            activeSound: activeSound,
            index: 1,
            onVolumeChange: { _ in },
            onRemove: {}
        )
        MixerSoundRowView(
            activeSound: activeSound,
            index: 12,
            onVolumeChange: { _ in },
            onRemove: {}
        )
    }
    .background(Tokens.colorCream)
}
