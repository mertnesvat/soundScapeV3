import SwiftUI
import WidgetKit
import AppIntents

// MARK: - Control Center Widget (iOS 18+)

/// Control Center toggle for SoundScape playback
/// Users can add this control to Control Center for quick play/pause access
@available(iOS 18.0, *)
struct SoundScapeControl: ControlWidget {
    static let kind: String = "SoundScapeControl"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: TogglePlaybackControlIntent()) {
                let state = WidgetSharedState.load()
                let isPlaying = state?.isPlaying ?? false
                let soundCount = state?.activeSoundNames.count ?? 0

                Label {
                    if isPlaying {
                        Text("Playing \(soundCount) \(soundCount == 1 ? "sound" : "sounds")")
                    } else if soundCount > 0 {
                        Text("Paused")
                    } else {
                        Text("Tap to start")
                    }
                } icon: {
                    Image(systemName: isPlaying ? "waveform" : "waveform.slash")
                }
            }
        }
        .displayName("SoundScape")
        .description("Toggle sound playback")
    }
}

// MARK: - Toggle Playback Intent for Control Widget

/// App Intent for toggling playback from Control Center
/// Uses URL scheme to communicate with main app since widget extensions
/// cannot directly access app services
@available(iOS 18.0, *)
struct TogglePlaybackControlIntent: ControlConfigurationIntent {
    static var title: LocalizedStringResource = "Toggle SoundScape"
    static var description = IntentDescription("Toggle sound playback")

    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        // Read current state from shared storage
        let state = WidgetSharedState.load()
        let isPlaying = state?.isPlaying ?? false

        // Store the action we want to perform
        // The main app will read this and execute the appropriate action
        if let defaults = UserDefaults(suiteName: WidgetSharedState.appGroupIdentifier) {
            defaults.set(isPlaying ? "pause" : "play", forKey: "pendingControlAction")
        }

        return .result()
    }
}
