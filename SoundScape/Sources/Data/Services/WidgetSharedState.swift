import Foundation
import WidgetKit

/// Shared state model for communicating between main app and widget
/// Stored in App Group UserDefaults for cross-process access
struct WidgetSharedState: Codable {
    let isPlaying: Bool
    let activeSoundNames: [String]
    let timerEndDate: Date?
    let lastUpdated: Date

    static let appGroupIdentifier = "group.com.StudioNext.SoundScape"

    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    private static let stateKey = "widgetSharedState"

    // MARK: - Read State

    static func load() -> WidgetSharedState? {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: stateKey) else {
            return nil
        }
        return try? JSONDecoder().decode(WidgetSharedState.self, from: data)
    }

    // MARK: - Write State

    static func save(_ state: WidgetSharedState) {
        guard let defaults = sharedDefaults,
              let data = try? JSONEncoder().encode(state) else {
            return
        }
        defaults.set(data, forKey: stateKey)

        // Trigger widget timeline refresh
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Convenience Methods

    /// Update only playback state (called from AudioEngine)
    static func updatePlaybackState(isPlaying: Bool, activeSoundNames: [String]) {
        let currentState = load()
        let newState = WidgetSharedState(
            isPlaying: isPlaying,
            activeSoundNames: activeSoundNames,
            timerEndDate: currentState?.timerEndDate,
            lastUpdated: Date()
        )
        save(newState)
    }

    /// Update only timer state (called from SleepTimerService)
    static func updateTimerState(timerEndDate: Date?) {
        let currentState = load()
        let newState = WidgetSharedState(
            isPlaying: currentState?.isPlaying ?? false,
            activeSoundNames: currentState?.activeSoundNames ?? [],
            timerEndDate: timerEndDate,
            lastUpdated: Date()
        )
        save(newState)
    }

    /// Clear all state (called when app stops all sounds)
    static func clearState() {
        let newState = WidgetSharedState(
            isPlaying: false,
            activeSoundNames: [],
            timerEndDate: nil,
            lastUpdated: Date()
        )
        save(newState)
    }

    // MARK: - Computed Properties

    var timerRemainingSeconds: Int? {
        guard let endDate = timerEndDate else { return nil }
        let remaining = Int(endDate.timeIntervalSinceNow)
        return remaining > 0 ? remaining : nil
    }

    var timerRemainingFormatted: String? {
        guard let seconds = timerRemainingSeconds else { return nil }
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    var displaySoundNames: String {
        if activeSoundNames.isEmpty {
            return "No sounds playing"
        }
        if activeSoundNames.count == 1 {
            return activeSoundNames[0]
        }
        if activeSoundNames.count == 2 {
            return activeSoundNames.joined(separator: " & ")
        }
        return "\(activeSoundNames[0]) +\(activeSoundNames.count - 1)"
    }
}
