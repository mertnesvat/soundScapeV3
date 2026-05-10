import SwiftUI

struct SavedMixesView: View {
    @Environment(SavedMixesService.self) private var mixesService
    @Environment(AudioEngine.self) private var audioEngine

    private let soundRepository: SoundRepositoryProtocol = SoundRepository()

    var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.surface.ignoresSafeArea()

                if mixesService.mixes.isEmpty {
                    Text(LocalizedStringKey("No saved mixes yet."))
                        .font(.body.weight(DesignTokens.font.body))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .multilineTextAlignment(.center)
                } else {
                    List {
                        ForEach(mixesService.mixes) { mix in
                            Button {
                                loadMix(mix)
                            } label: {
                                row(for: mix)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .accessibilityLabel(Text("Play \(mix.name)"))
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { mixesService.deleteMix(mixesService.mixes[$0]) }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle(LocalizedStringKey("Saved Mixes"))
        }
    }

    private func row(for mix: SavedMix) -> some View {
        HStack(spacing: DesignTokens.padding.standard) {
            VStack(alignment: .leading, spacing: 4) {
                Text(mix.name)
                    .font(.body.weight(DesignTokens.font.body))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text("\(mix.sounds.count) sound\(mix.sounds.count == 1 ? "" : "s")")
                    .font(.caption.weight(DesignTokens.font.body))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "play.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(DesignTokens.accent)
                .accessibilityHidden(true)
        }
        .padding(.vertical, DesignTokens.padding.compact)
        .contentShape(Rectangle())
    }

    private func loadMix(_ mix: SavedMix) {
        audioEngine.stopAll()

        // Small delay to let stopAll complete with fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            for mixSound in mix.sounds {
                if let sound = soundRepository.getSound(byId: mixSound.soundId) {
                    audioEngine.play(sound: sound)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        audioEngine.setVolume(mixSound.volume, for: sound.id)
                    }
                }
            }
        }
    }
}

#Preview {
    SavedMixesView()
        .environment(SavedMixesService())
        .environment(AudioEngine())
        .preferredColorScheme(.dark)
}
