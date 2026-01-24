import Foundation
import SwiftUI

@Observable
@MainActor
final class AppearanceService {
    private let oledModeKey = "oled_mode_enabled"
    private(set) var isOLEDModeEnabled: Bool = false

    init() {
        loadSettings()
    }

    func toggleOLEDMode() {
        isOLEDModeEnabled.toggle()
        saveSettings()
    }

    func setOLEDMode(_ enabled: Bool) {
        guard isOLEDModeEnabled != enabled else { return }
        isOLEDModeEnabled = enabled
        saveSettings()
    }

    private func loadSettings() {
        isOLEDModeEnabled = UserDefaults.standard.bool(forKey: oledModeKey)
    }

    private func saveSettings() {
        UserDefaults.standard.set(isOLEDModeEnabled, forKey: oledModeKey)
    }
}
