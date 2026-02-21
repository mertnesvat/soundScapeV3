import SwiftUI

struct MixerView: View {
    @Environment(AudioEngine.self) private var audioEngine
    @Environment(SavedMixesService.self) private var mixesService
    @Environment(PaywallService.self) private var paywallService
    @Environment(SubscriptionService.self) private var subscriptionService
    @State private var showSaveMixSheet = false

    private let freeSoundLimit = 6

    var body: some View {
        NavigationStack {
            Group {
                if audioEngine.activeSounds.isEmpty {
                    // Empty state
                    ContentUnavailableView(
                        String(localized: "No Sounds Playing"),
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
                            HStack {
                                Text("\(audioEngine.activeSounds.count) sound\(audioEngine.activeSounds.count == 1 ? "" : "s") playing")
                                Spacer()
                                if paywallService.isPremium {
                                    Text("\(audioEngine.activeSounds.count)/∞")
                                        .foregroundColor(.green)
                                } else {
                                    HStack(spacing: 4) {
                                        Text("\(audioEngine.activeSounds.count)/\(freeSoundLimit)")
                                        if audioEngine.activeSounds.count >= freeSoundLimit {
                                            Image(systemName: "lock.fill")
                                                .font(.caption2)
                                        }
                                    }
                                    .foregroundColor(audioEngine.activeSounds.count >= freeSoundLimit ? .orange : .secondary)
                                }
                            }
                            .textCase(nil)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle(LocalizedStringKey("Mixer"))
            .toolbar {
                if !audioEngine.activeSounds.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Save Mix") {
                            if mixesService.mixes.count >= PaywallService.freeSavedMixesLimit {
                                paywallService.triggerSmartPaywall(source: "saved_mixes_limit") {
                                    showSaveMixSheet = true
                                }
                            } else {
                                showSaveMixSheet = true
                            }
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: 16) {
                            Button {
                                if audioEngine.isAnyPlaying {
                                    audioEngine.pauseAll()
                                } else {
                                    audioEngine.resumeAll()
                                }
                            } label: {
                                Image(
                                    systemName: audioEngine.isAnyPlaying
                                        ? "pause.fill" : "play.fill")
                            }

                            Button {
                                audioEngine.stopAll()
                            } label: {
                                Image(systemName: "stop.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showSaveMixSheet) {
                SaveMixSheet { name in
                    mixesService.saveMix(name: name, sounds: audioEngine.activeSounds)
                }
            }
            .sheet(isPresented: Binding(
                get: { paywallService.showPaywall },
                set: { newValue in
                    if !newValue {
                        paywallService.handlePaywallDismissed()
                    }
                }
            )) {
                SmartPaywallView()
                    .environment(paywallService)
                    .environment(subscriptionService)
            }
        }
    }
}

#Preview {
    MixerView()
        .environment(AudioEngine())
        .environment(SavedMixesService())
        .environment(PaywallService())
        .environment(SubscriptionService())
        .preferredColorScheme(.dark)
}
