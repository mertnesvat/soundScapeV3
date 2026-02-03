import SwiftUI

struct SavedMixesView: View {
    @Environment(SavedMixesService.self) private var mixesService
    @Environment(AudioEngine.self) private var audioEngine

    private let soundRepository: SoundRepositoryProtocol = SoundRepository()

    var body: some View {
        NavigationStack {
            Group {
                if mixesService.mixes.isEmpty {
                    ContentUnavailableView(
                        String(localized: "No Saved Mixes"),
                        systemImage: "folder.badge.plus",
                        description: Text("Save your current sound mix from the Mixer")
                    )
                } else {
                    List {
                        ForEach(mixesService.mixes) { mix in
                            SavedMixRowView(
                                mix: mix,
                                soundRepository: soundRepository,
                                onPlay: { loadMix(mix) },
                                onRename: { newName in mixesService.renameMix(mix, to: newName) }
                            )
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { mixesService.deleteMix(mixesService.mixes[$0]) }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle(LocalizedStringKey("Saved Mixes"))
        }
    }

    private func loadMix(_ mix: SavedMix) {
        audioEngine.stopAll()

        // Small delay to let stopAll complete with fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            for mixSound in mix.sounds {
                if let sound = soundRepository.getSound(byId: mixSound.soundId) {
                    audioEngine.play(sound: sound)
                    // Set volume after a brief delay to let play initialize
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
