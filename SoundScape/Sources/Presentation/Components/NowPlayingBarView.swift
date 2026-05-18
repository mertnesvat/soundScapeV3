import SwiftUI

/// Editorial now-playing bar — a saturated orange block inset from the screen
/// edges, with a white play/pause square chip on the left, white title /
/// subtitle in the centre, and a black-outlined chevron affordance on the
/// right that opens the Mixer. Replaces the legacy glassmorphic purple bar.
struct NowPlayingBarView: View {
    @Environment(AudioEngine.self) private var audioEngine
    @Binding var showMixer: Bool

    @State private var isPressed = false
    @State private var isPlayPausePressed = false

    var body: some View {
        if !audioEngine.activeSounds.isEmpty {
            HStack(spacing: 14) {
                playPauseChip

                titleBlock

                Spacer(minLength: 0)

                chevronAffordance
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: Tokens.radiusTile, style: .continuous)
                    .fill(Tokens.colorOrange)
            )
            .padding(.horizontal, 12)
            .scaleEffect(isPressed ? 0.97 : 1)
            .animation(Tokens.tactilePress, value: isPressed)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .contentShape(Rectangle())
            .onTapGesture {
                showMixer = true
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
        }
    }

    // MARK: - Left: white square play/pause chip

    private var playPauseChip: some View {
        Button {
            if audioEngine.isAnyPlaying {
                audioEngine.pauseAll()
            } else {
                audioEngine.resumeAll()
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.white)
                Image(systemName: audioEngine.isAnyPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Tokens.colorInk)
            }
            .frame(width: 24, height: 24)
            .scaleEffect(isPlayPausePressed ? 0.97 : 1)
            .animation(Tokens.tactilePress, value: isPlayPausePressed)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(audioEngine.isAnyPlaying ? "Pause" : "Play")
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPlayPausePressed = true }
                .onEnded { _ in isPlayPausePressed = false }
        )
    }

    // MARK: - Centre: title + subtitle in white

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("Now Playing")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)

            Text("\(audioEngine.activeSounds.count) sounds active")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color.white.opacity(0.8))
        }
        .lineLimit(1)
    }

    // MARK: - Right: 36pt black-outlined chevron circle opens Mixer

    private var chevronAffordance: some View {
        Button {
            showMixer = true
        } label: {
            ZStack {
                Circle()
                    .stroke(Tokens.colorInk, lineWidth: 1.5)
                    .frame(width: 36, height: 36)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Tokens.colorInk)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open mixer")
    }
}

#Preview {
    @Previewable @State var showMixer = false
    let audioEngine = AudioEngine()
    return NowPlayingBarView(showMixer: $showMixer)
        .environment(audioEngine)
        .padding(.vertical, 40)
        .background(Tokens.colorCream)
}
