import SwiftUI
import UIKit

@main
struct SoundScapeApp: App {
    @State private var audioEngine = AudioEngine()

    init() {
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(audioEngine)
                .preferredColorScheme(.dark)
        }
    }

    private func configureAppearance() {
        // Configure global appearance for dark mode
        UITabBar.appearance().backgroundColor = UIColor.systemBackground
    }
}
