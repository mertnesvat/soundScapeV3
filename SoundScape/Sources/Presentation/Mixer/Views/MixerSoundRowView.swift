import SwiftUI

struct MixerSoundRowView: View {
    let activeSound: ActiveSound
    let onVolumeChange: (Float) -> Void
    let onRemove: () -> Void

    @State private var volume: Float

    init(activeSound: ActiveSound, onVolumeChange: @escaping (Float) -> Void, onRemove: @escaping () -> Void) {
        self.activeSound = activeSound
        self.onVolumeChange = onVolumeChange
        self.onRemove = onRemove
        self._volume = State(initialValue: activeSound.volume)
    }

    var body: some View {
        HStack(spacing: 16) {
            // Category icon
            Image(systemName: activeSound.sound.category.icon)
                .font(.title2)
                .foregroundColor(categoryColor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 8) {
                // Sound name
                Text(activeSound.sound.name)
                    .font(.headline)

                // Volume slider with percentage
                HStack {
                    Image(systemName: "speaker.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Slider(value: $volume, in: 0...1) { _ in
                        onVolumeChange(volume)
                    }
                    .tint(categoryColor)

                    Text("\(Int(volume * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 40)
                }
            }

            // Remove button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }

    private var categoryColor: Color {
        switch activeSound.sound.category {
        case .noise: return .purple
        case .nature: return .green
        case .weather: return .blue
        case .fire: return .orange
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
