import SwiftUI

struct NowPlayingBarView: View {
    @Environment(AudioEngine.self) private var audioEngine
    @Binding var showMixer: Bool

    var body: some View {
        if !audioEngine.activeSounds.isEmpty {
            let count = audioEngine.activeSounds.count
            let isPlaying = audioEngine.isAnyPlaying

            HStack(spacing: DesignTokens.padding.compact) {
                Button(action: { showMixer = true }) {
                    Text("\(count) sound\(count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .fontWeight(DesignTokens.font.body)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button {
                    if isPlaying { audioEngine.pauseAll() } else { audioEngine.resumeAll() }
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.headline)
                        .foregroundColor(DesignTokens.accent)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DesignTokens.padding.standard)
            .padding(.vertical, DesignTokens.padding.compact)
            .background(
                Capsule()
                    .fill(DesignTokens.surface.opacity(0.85))
                    .shadow(
                        color: DesignTokens.accent.opacity(isPlaying ? DesignTokens.shadow.opacity : 0),
                        radius: DesignTokens.shadow.minRadius
                    )
            )
            .overlay(
                Capsule().stroke(DesignTokens.accent.opacity(0.25), lineWidth: 0.5)
            )
            .padding(.horizontal, DesignTokens.padding.edges)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(DesignTokens.spring.gentle, value: isPlaying)
            .sheet(isPresented: $showMixer) { MixerView() }
        }
    }
}

#Preview {
    @Previewable @State var showMixer = false
    let audioEngine = AudioEngine()
    return NowPlayingBarView(showMixer: $showMixer)
        .environment(audioEngine)
        .preferredColorScheme(.dark)
}
