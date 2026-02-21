import XCTest
@testable import SoundScape

@MainActor
final class QuickStartPresetsTests: XCTestCase {

    // MARK: - SoundPreset Tests

    func test_quickStartPresets_hasFivePresets() {
        let presets = SoundPreset.quickStartPresets

        XCTAssertEqual(presets.count, 5)
    }

    func test_quickStartPresets_haveUniqueIds() {
        let presets = SoundPreset.quickStartPresets
        let ids = presets.map { $0.id }
        let uniqueIds = Set(ids)

        XCTAssertEqual(ids.count, uniqueIds.count)
    }

    func test_quickStartPresets_eachHasSoundConfigs() {
        let presets = SoundPreset.quickStartPresets

        for preset in presets {
            XCTAssertFalse(preset.soundConfigs.isEmpty, "Preset '\(preset.name)' has no sound configs")
            XCTAssertGreaterThanOrEqual(preset.soundConfigs.count, 2, "Preset '\(preset.name)' should have at least 2 sounds")
            XCTAssertLessThanOrEqual(preset.soundConfigs.count, 4, "Preset '\(preset.name)' should have at most 4 sounds")
        }
    }

    func test_quickStartPresets_allSoundIdsExistInDataSource() {
        let presets = SoundPreset.quickStartPresets
        let allSounds = LocalSoundDataSource.shared.getAllSounds()
        let soundIds = Set(allSounds.map { $0.id })

        for preset in presets {
            for config in preset.soundConfigs {
                XCTAssertTrue(soundIds.contains(config.soundId), "Sound ID '\(config.soundId)' in preset '\(preset.name)' not found in data source")
            }
        }
    }

    func test_quickStartPresets_volumesAreInValidRange() {
        let presets = SoundPreset.quickStartPresets

        for preset in presets {
            for config in preset.soundConfigs {
                XCTAssertGreaterThan(config.volume, 0, "Volume for '\(config.soundId)' in preset '\(preset.name)' should be > 0")
                XCTAssertLessThanOrEqual(config.volume, 1, "Volume for '\(config.soundId)' in preset '\(preset.name)' should be <= 1")
            }
        }
    }

    func test_quickStartPresets_haveExpectedNames() {
        let presets = SoundPreset.quickStartPresets
        let ids = presets.map { $0.id }

        XCTAssertTrue(ids.contains("deep_sleep"))
        XCTAssertTrue(ids.contains("focus_flow"))
        XCTAssertTrue(ids.contains("rain_day"))
        XCTAssertTrue(ids.contains("ocean_calm"))
        XCTAssertTrue(ids.contains("forest_morning"))
    }

    func test_quickStartPresets_eachHasGradientColors() {
        let presets = SoundPreset.quickStartPresets

        for preset in presets {
            XCTAssertEqual(preset.gradientColors.count, 2, "Preset '\(preset.name)' should have exactly 2 gradient colors")
        }
    }

    func test_quickStartPresets_eachHasIcon() {
        let presets = SoundPreset.quickStartPresets

        for preset in presets {
            XCTAssertFalse(preset.icon.isEmpty, "Preset '\(preset.name)' should have an icon")
        }
    }

    // MARK: - QuickStartPresetsService Tests

    func test_service_init_startsNotCollapsed() {
        // Clear UserDefaults for this test
        UserDefaults.standard.removeObject(forKey: "quick_start_presets_collapsed")

        let sut = QuickStartPresetsService()

        XCTAssertFalse(sut.isCollapsed)
    }

    func test_service_toggleCollapsed_changesState() {
        UserDefaults.standard.removeObject(forKey: "quick_start_presets_collapsed")

        let sut = QuickStartPresetsService()
        XCTAssertFalse(sut.isCollapsed)

        sut.toggleCollapsed()
        XCTAssertTrue(sut.isCollapsed)

        sut.toggleCollapsed()
        XCTAssertFalse(sut.isCollapsed)
    }

    func test_service_toggleCollapsed_persistsState() {
        UserDefaults.standard.removeObject(forKey: "quick_start_presets_collapsed")

        let sut1 = QuickStartPresetsService()
        sut1.toggleCollapsed()
        XCTAssertTrue(sut1.isCollapsed)

        let sut2 = QuickStartPresetsService()
        XCTAssertTrue(sut2.isCollapsed)

        // Clean up
        UserDefaults.standard.removeObject(forKey: "quick_start_presets_collapsed")
    }

    func test_service_presets_returnsFivePresets() {
        let sut = QuickStartPresetsService()

        XCTAssertEqual(sut.presets.count, 5)
    }

    func test_service_activePresetId_startsNil() {
        let sut = QuickStartPresetsService()

        XCTAssertNil(sut.activePresetId)
    }

    func test_service_clearActivePreset_setsToNil() {
        let sut = QuickStartPresetsService()

        sut.clearActivePreset()

        XCTAssertNil(sut.activePresetId)
    }

    func test_service_loadPreset_setsActivePresetId() {
        let sut = QuickStartPresetsService()
        let audioEngine = AudioEngine()
        let allSounds = LocalSoundDataSource.shared.getAllSounds()
        let preset = SoundPreset.quickStartPresets[0]

        sut.loadPreset(preset, audioEngine: audioEngine, allSounds: allSounds)

        XCTAssertEqual(sut.activePresetId, preset.id)
    }

    // MARK: - SoundPreset Equatable Tests

    func test_soundPreset_equatable() {
        let presets = SoundPreset.quickStartPresets
        let first = presets[0]
        let second = presets[1]

        XCTAssertEqual(first, first)
        XCTAssertNotEqual(first, second)
    }
}
