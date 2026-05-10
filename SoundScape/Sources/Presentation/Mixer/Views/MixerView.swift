import SwiftUI

struct MixerView: View {
    @Environment(AudioEngine.self) private var audioEngine
    @Environment(SavedMixesService.self) private var mixesService
    @Environment(AnalyticsService.self) private var analyticsService
    @Environment(\.dismiss) private var dismiss
    @State private var showSaveMixSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.surface.ignoresSafeArea()

                if audioEngine.activeSounds.isEmpty {
                    ContentUnavailableView(
                        String(localized: "No Sounds Playing"),
                        systemImage: "speaker.slash",
                        description: Text("Start playing sounds from the library")
                    )
                } else {
                    VStack(spacing: DesignTokens.padding.standard) {
                        ScrollView {
                            VStack(spacing: DesignTokens.padding.standard) {
                                ForEach(audioEngine.activeSounds) { activeSound in
                                    MixerSoundRowView(
                                        activeSound: activeSound,
                                        onVolumeChange: { volume in
                                            audioEngine.setVolume(volume, for: activeSound.id)
                                        },
                                        onRemove: {
                                            analyticsService.logMixerSoundRemoved(
                                                soundId: activeSound.id,
                                                totalActive: audioEngine.activeSounds.count - 1
                                            )
                                            audioEngine.stop(soundId: activeSound.id)
                                        },
                                        onVolumeCommit: { volume in
                                            analyticsService.logVolumeAdjusted(
                                                soundId: activeSound.id,
                                                newVolume: volume
                                            )
                                        }
                                    )
                                }
                            }
                            .padding(.top, DesignTokens.padding.standard)
                        }

                        Button {
                            audioEngine.stopAll()
                            dismiss()
                        } label: {
                            Text("Stop all")
                                .font(.body.weight(DesignTokens.font.body))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, DesignTokens.padding.compact)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(DesignTokens.accent)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radius.button))
                    }
                    .padding(DesignTokens.padding.standard)
                }
            }
            .navigationTitle(LocalizedStringKey("Mixer"))
            .toolbar {
                if !audioEngine.activeSounds.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Save Mix") {
                            showSaveMixSheet = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showSaveMixSheet) {
                SaveMixSheet { name in
                    mixesService.saveMix(name: name, sounds: audioEngine.activeSounds)
                }
            }
            .onAppear {
                analyticsService.logMixerOpened(activeSoundCount: audioEngine.activeSounds.count)
            }
        }
    }
}

#Preview {
    MixerView()
        .environment(AudioEngine())
        .environment(SavedMixesService())
        .environment(PaywallService())
        .environment(AnalyticsService())
        .preferredColorScheme(.dark)
}
