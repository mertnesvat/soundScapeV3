import SwiftUI
import UIKit

@main
struct SoundScapeApp: App {
    @State private var audioEngine = AudioEngine()
    @State private var sleepTimerService: SleepTimerService?

    init() {
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(audioEngine)
                .environment(sleepTimerService ?? createSleepTimerService())
                .preferredColorScheme(.dark)
                .onAppear {
                    if sleepTimerService == nil {
                        sleepTimerService = SleepTimerService(audioEngine: audioEngine)
                    }
                }
        }
    }

    @MainActor
    private func createSleepTimerService() -> SleepTimerService {
        SleepTimerService(audioEngine: audioEngine)
    }

    private func configureAppearance() {
        // Configure global appearance for dark mode
        UITabBar.appearance().backgroundColor = UIColor.systemBackground
    }
}
