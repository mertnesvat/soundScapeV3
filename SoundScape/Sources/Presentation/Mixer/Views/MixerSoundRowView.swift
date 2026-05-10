import SwiftUI

struct MixerSoundRowView: View {
    let activeSound: ActiveSound
    let onVolumeChange: (Float) -> Void
    let onRemove: () -> Void
    var onVolumeCommit: ((Float) -> Void)?

    @State private var volume: Float

    init(activeSound: ActiveSound, onVolumeChange: @escaping (Float) -> Void, onRemove: @escaping () -> Void, onVolumeCommit: ((Float) -> Void)? = nil) {
        self.activeSound = activeSound
        self.onVolumeChange = onVolumeChange
        self.onRemove = onRemove
        self.onVolumeCommit = onVolumeCommit
        self._volume = State(initialValue: activeSound.volume)
    }

    var body: some View {
        HStack(spacing: DesignTokens.padding.standard) {
            Text(activeSound.sound.name)
                .font(.body.weight(DesignTokens.font.body))
                .foregroundColor(.primary)
                .lineLimit(1)
                .frame(width: 100, alignment: .leading)

            Slider(value: $volume, in: 0...1) { editing in
                onVolumeChange(volume)
                if !editing {
                    onVolumeCommit?(volume)
                }
            }
            .tint(DesignTokens.accent)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Remove \(activeSound.sound.name)"))
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

    return MixerSoundRowView(
        activeSound: activeSound,
        onVolumeChange: { _ in },
        onRemove: {}
    )
    .preferredColorScheme(.dark)
    .padding()
}
