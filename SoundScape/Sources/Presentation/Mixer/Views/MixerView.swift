import SwiftUI

struct MixerView: View {
    @Environment(AudioEngine.self) private var audioEngine
    @Environment(SavedMixesService.self) private var mixesService
    @State private var showSaveMixSheet = false

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
                        // Visualization section at top
                        Section {
                            LiquidVisualizationView(
                                activeSounds: audioEngine.activeSounds,
                                height: 150
                            )
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                        }

                        // Sound controls section
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
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Save Mix") {
                            showSaveMixSheet = true
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Stop All") {
                            audioEngine.stopAll()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .sheet(isPresented: $showSaveMixSheet) {
                SaveMixSheet { name in
                    mixesService.saveMix(name: name, sounds: audioEngine.activeSounds)
                }
            }
        }
    }
}

#Preview {
    MixerView()
        .environment(AudioEngine())
        .environment(SavedMixesService())
        .preferredColorScheme(.dark)
}
