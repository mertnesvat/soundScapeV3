import AppIntents

/// App Shortcuts provider for SoundScape
/// Registers all Siri voice commands and Shortcuts app integration
struct SoundScapeShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        // "Hey Siri, I can't sleep with SoundScape"
        AppShortcut(
            intent: StartSleepMixIntent(),
            phrases: [
                "I can't sleep with \(.applicationName)",
                "Help me sleep with \(.applicationName)",
                "Start sleep sounds with \(.applicationName)",
                "Play sleep sounds with \(.applicationName)"
            ],
            shortTitle: "I Can't Sleep",
            systemImageName: "moon.zzz.fill"
        )

        // "Hey Siri, play my rain mix with SoundScape"
        AppShortcut(
            intent: PlaySavedMixIntent(),
            phrases: [
                "Play \(\.$mix) with \(.applicationName)",
                "Start \(\.$mix) with \(.applicationName)",
                "Play my \(\.$mix) mix with \(.applicationName)"
            ],
            shortTitle: "Play Saved Mix",
            systemImageName: "music.note.list"
        )

        // "Hey Siri, set sleep timer with SoundScape"
        AppShortcut(
            intent: SetSleepTimerIntent(),
            phrases: [
                "Set sleep timer with \(.applicationName)",
                "Start sleep timer with \(.applicationName)",
                "Fade out with \(.applicationName)"
            ],
            shortTitle: "Set Sleep Timer",
            systemImageName: "timer"
        )

        // "Hey Siri, stop SoundScape"
        AppShortcut(
            intent: StopSoundsIntent(),
            phrases: [
                "Stop \(.applicationName)",
                "Stop sounds with \(.applicationName)",
                "Pause \(.applicationName)",
                "Turn off \(.applicationName)"
            ],
            shortTitle: "Stop Sounds",
            systemImageName: "stop.fill"
        )

        // "Hey Siri, resume SoundScape"
        AppShortcut(
            intent: ResumeSoundsIntent(),
            phrases: [
                "Resume \(.applicationName)",
                "Continue \(.applicationName)",
                "Resume sounds with \(.applicationName)",
                "Unpause \(.applicationName)"
            ],
            shortTitle: "Resume Sounds",
            systemImageName: "play.fill"
        )
    }
}
