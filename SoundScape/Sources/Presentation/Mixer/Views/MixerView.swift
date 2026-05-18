import SwiftUI

/// Editorial mixer sheet — cream canvas with a thick orange `MIXER` header
/// block, a black-outlined square close chip, and a vertical stack of
/// numbered editorial sound rows. Replaces the legacy purple/dark inset list.
struct MixerView: View {
    @Environment(AudioEngine.self) private var audioEngine
    @Environment(SavedMixesService.self) private var mixesService
    @Environment(PaywallService.self) private var paywallService
    @Environment(AnalyticsService.self) private var analyticsService
    @Environment(\.dismiss) private var dismiss
    @State private var showSaveMixSheet = false

    private let freeSoundLimit = 6

    private var counterText: String {
        if paywallService.isPremium {
            return "\(audioEngine.activeSounds.count)/∞"
        } else {
            return "\(audioEngine.activeSounds.count)/\(freeSoundLimit)"
        }
    }

    private var counterIsAtCap: Bool {
        !paywallService.isPremium && audioEngine.activeSounds.count >= freeSoundLimit
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                editorialHeader

                if audioEngine.activeSounds.isEmpty {
                    emptyState
                } else {
                    controlStrip
                    activeSoundsList
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Tokens.colorCream.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
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

    // MARK: - Header (thick orange MIXER block)

    private var editorialHeader: some View {
        ZStack(alignment: .topTrailing) {
            Tokens.colorOrange
                .ignoresSafeArea(edges: .top)

            HStack {
                Text("MIXER")
                    .font(.system(size: 34, weight: .black, design: .default))
                    .tracking(1.0)
                    .foregroundColor(.white)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Tokens.colorInk)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Tokens.colorOrange)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Tokens.colorInk, lineWidth: 1.5)
                    )
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Close mixer")
            .padding(.trailing, 20)
            .padding(.top, 20)
        }
        .frame(minHeight: 96)
    }

    // MARK: - Control strip (Save / Pause-Play / Stop)

    private var controlStrip: some View {
        HStack(spacing: 0) {
            Text(counterText)
                .font(.system(size: 13, weight: .bold, design: .default))
                .tracking(1.2)
                .foregroundColor(counterIsAtCap ? Tokens.colorOrange : Tokens.colorInk.opacity(0.6))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(counterIsAtCap ? Tokens.colorOrange : Tokens.colorInk.opacity(0.2), lineWidth: 1)
                )

            Spacer(minLength: 0)

            HStack(spacing: 12) {
                Button {
                    showSaveMixSheet = true
                } label: {
                    Text("SAVE MIX")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1.0)
                        .foregroundColor(Tokens.colorInk)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Tokens.colorInk, lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Save mix")

                Button {
                    if audioEngine.isAnyPlaying {
                        audioEngine.pauseAll()
                    } else {
                        audioEngine.resumeAll()
                    }
                } label: {
                    Image(systemName: audioEngine.isAnyPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Tokens.colorInk)
                        .frame(width: 36, height: 36)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Tokens.colorInk, lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(audioEngine.isAnyPlaying ? "Pause all" : "Resume all")

                Button {
                    audioEngine.stopAll()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Tokens.colorInk)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Stop all")
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    // MARK: - Active sounds list

    private var activeSoundsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(audioEngine.activeSounds.enumerated()), id: \.element.id) { offset, activeSound in
                    MixerSoundRowView(
                        activeSound: activeSound,
                        index: offset + 1,
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
            .padding(.bottom, 32)
        }
        .background(Tokens.colorCream)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "speaker.slash")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(Tokens.colorInk.opacity(0.4))
            Text("No Sounds Playing")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Tokens.colorInk)
            Text("Start playing sounds from the library")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Tokens.colorInk.opacity(0.6))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .background(Tokens.colorCream)
    }
}

#Preview {
    MixerView()
        .environment(AudioEngine())
        .environment(SavedMixesService())
        .environment(PaywallService())
        .environment(AnalyticsService())
}
