import SwiftUI

struct MixerView: View {
    @Environment(AudioEngine.self) private var audioEngine

    var body: some View {
        NavigationStack {
            Group {
                if audioEngine.activeSounds.isEmpty {
                    // Empty state
                    ContentUnavailableView(
                        "No Sounds Playing",
                        systemImage: "speaker.slash",
                        description: Text("Start playing sounds from the library")
                    )
                } else {
                    // List of active sounds with volume controls
                    List {
                        // Header showing count
                        Section {
                            ForEach(audioEngine.activeSounds) { activeSound in
                                MixerSoundRowView(
                                    activeSound: activeSound,
                                    onVolumeChange: { volume in
                                        audioEngine.setVolume(volume, for: activeSound.id)
                                    },
                                    onRemove: {
                                        audioEngine.stop(soundId: activeSound.id)
                                    }
                                )
                            }
                        } header: {
                            Text("\(audioEngine.activeSounds.count) sound\(audioEngine.activeSounds.count == 1 ? "" : "s") playing")
                                .textCase(nil)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Mixer")
            .toolbar {
                if !audioEngine.activeSounds.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Stop All") {
                            audioEngine.stopAll()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
    }
}

#Preview {
    MixerView()
        .environment(AudioEngine())
        .preferredColorScheme(.dark)
}
