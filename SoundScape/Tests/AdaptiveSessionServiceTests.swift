import XCTest
@testable import SoundScape

final class AdaptiveSessionServiceTests: XCTestCase {

    // MARK: - Test Helpers

    @MainActor
    private func makeSUT() -> AdaptiveSessionService {
        let audioEngine = AudioEngine()
        return AdaptiveSessionService(audioEngine: audioEngine)
    }

    // MARK: - Initial State Tests

    @MainActor
    func test_init_isNotActive() {
        let sut = makeSUT()

        XCTAssertFalse(sut.isActive)
    }

    @MainActor
    func test_init_hasNoCurrentMode() {
        let sut = makeSUT()

        XCTAssertNil(sut.currentMode)
    }

    @MainActor
    func test_init_currentPhaseIndexIsZero() {
        let sut = makeSUT()

        XCTAssertEqual(sut.currentPhaseIndex, 0)
    }

    @MainActor
    func test_init_phaseTimeRemainingIsZero() {
        let sut = makeSUT()

        XCTAssertEqual(sut.phaseTimeRemaining, 0)
    }

    @MainActor
    func test_init_currentPhaseIsNil() {
        let sut = makeSUT()

        XCTAssertNil(sut.currentPhase)
    }

    @MainActor
    func test_init_elapsedTimeIsZero() {
        let sut = makeSUT()

        XCTAssertEqual(sut.elapsedTime, 0)
    }

    @MainActor
    func test_init_progressIsZero() {
        let sut = makeSUT()

        XCTAssertEqual(sut.progress, 0)
    }

    @MainActor
    func test_init_phaseProgressIsZero() {
        let sut = makeSUT()

        XCTAssertEqual(sut.phaseProgress, 0)
    }

    // MARK: - Start Tests

    @MainActor
    func test_start_setsActiveToTrue() {
        let sut = makeSUT()

        sut.start(mode: .sleepCycle)

        XCTAssertTrue(sut.isActive)
    }

    @MainActor
    func test_start_setsCurrentMode() {
        let sut = makeSUT()

        sut.start(mode: .focusSession)

        XCTAssertEqual(sut.currentMode, .focusSession)
    }

    @MainActor
    func test_start_resetsPhaseIndexToZero() {
        let sut = makeSUT()

        sut.start(mode: .sleepCycle)

        XCTAssertEqual(sut.currentPhaseIndex, 0)
    }

    @MainActor
    func test_start_setsPhaseTimeRemainingToFirstPhaseDurationInSeconds() {
        let sut = makeSUT()

        sut.start(mode: .sleepCycle)

        let expectedSeconds = AdaptiveMode.sleepCycle.phases[0].duration * 60
        XCTAssertEqual(sut.phaseTimeRemaining, expectedSeconds)
    }

    @MainActor
    func test_start_setsCurrentPhaseToFirstPhase() {
        let sut = makeSUT()

        sut.start(mode: .dayNight)

        XCTAssertEqual(sut.currentPhase?.name, "Morning Energy")
    }

    // MARK: - Stop Tests

    @MainActor
    func test_stop_setsActiveToFalse() {
        let sut = makeSUT()
        sut.start(mode: .sleepCycle)

        sut.stop()

        XCTAssertFalse(sut.isActive)
    }

    @MainActor
    func test_stop_clearsCurrentMode() {
        let sut = makeSUT()
        sut.start(mode: .sleepCycle)

        sut.stop()

        XCTAssertNil(sut.currentMode)
    }

    @MainActor
    func test_stop_resetsPhaseIndex() {
        let sut = makeSUT()
        sut.start(mode: .sleepCycle)

        sut.stop()

        XCTAssertEqual(sut.currentPhaseIndex, 0)
    }

    @MainActor
    func test_stop_resetsPhaseTimeRemaining() {
        let sut = makeSUT()
        sut.start(mode: .sleepCycle)

        sut.stop()

        XCTAssertEqual(sut.phaseTimeRemaining, 0)
    }

    @MainActor
    func test_stop_whenNotActive_doesNotCrash() {
        let sut = makeSUT()

        sut.stop()

        XCTAssertFalse(sut.isActive)
    }

    // MARK: - Start After Stop Tests

    @MainActor
    func test_start_afterStop_resetsState() {
        let sut = makeSUT()
        sut.start(mode: .sleepCycle)
        sut.stop()

        sut.start(mode: .focusSession)

        XCTAssertTrue(sut.isActive)
        XCTAssertEqual(sut.currentMode, .focusSession)
        XCTAssertEqual(sut.currentPhaseIndex, 0)
    }

    @MainActor
    func test_start_whileAlreadyActive_stopsAndRestarts() {
        let sut = makeSUT()
        sut.start(mode: .sleepCycle)

        sut.start(mode: .focusSession)

        XCTAssertTrue(sut.isActive)
        XCTAssertEqual(sut.currentMode, .focusSession)
    }

    // MARK: - Computed Properties Tests

    @MainActor
    func test_totalDuration_returnsCorrectSumOfPhaseDurations() {
        let sut = makeSUT()
        sut.start(mode: .sleepCycle)

        // sleepCycle phases: 15 + 20 + 40 + 20 = 95 minutes
        XCTAssertEqual(sut.totalDuration, 95)
    }

    @MainActor
    func test_totalDuration_whenNoMode_returnsZero() {
        let sut = makeSUT()

        XCTAssertEqual(sut.totalDuration, 0)
    }

    @MainActor
    func test_totalTimeInSeconds_returnsTotalDurationTimeSixty() {
        let sut = makeSUT()
        sut.start(mode: .sleepCycle)

        XCTAssertEqual(sut.totalTimeInSeconds, 95 * 60)
    }

    @MainActor
    func test_progress_atStart_isZero() {
        let sut = makeSUT()
        sut.start(mode: .sleepCycle)

        // At start: elapsed = (15*60 - phaseTimeRemaining) = (900 - 900) = 0
        // progress = 0 / (95 * 60) = 0
        XCTAssertEqual(sut.progress, 0, accuracy: 0.001)
    }

    @MainActor
    func test_phaseProgress_atPhaseStart_isZero() {
        let sut = makeSUT()
        sut.start(mode: .sleepCycle)

        // phaseTimeRemaining == phase.duration * 60, so progress = 0
        XCTAssertEqual(sut.phaseProgress, 0, accuracy: 0.001)
    }

    // MARK: - AdaptiveMode Properties Tests

    func test_allModes_havePhases() {
        for mode in AdaptiveMode.allCases {
            XCTAssertFalse(mode.phases.isEmpty, "\(mode.rawValue) should have phases")
        }
    }

    func test_sleepCycle_hasFourPhases() {
        XCTAssertEqual(AdaptiveMode.sleepCycle.phases.count, 4)
    }

    func test_dayNight_hasFourPhases() {
        XCTAssertEqual(AdaptiveMode.dayNight.phases.count, 4)
    }

    func test_weatherSync_hasFivePhases() {
        XCTAssertEqual(AdaptiveMode.weatherSync.phases.count, 5)
    }

    func test_focusSession_hasSixPhases() {
        XCTAssertEqual(AdaptiveMode.focusSession.phases.count, 6)
    }

    func test_allModes_havePositivePhaseDurations() {
        for mode in AdaptiveMode.allCases {
            for phase in mode.phases {
                XCTAssertGreaterThan(phase.duration, 0, "Phase '\(phase.name)' in \(mode.rawValue) should have positive duration")
            }
        }
    }

    func test_allModes_haveNonEmptyPhaseSounds() {
        for mode in AdaptiveMode.allCases {
            for phase in mode.phases {
                XCTAssertFalse(phase.sounds.isEmpty, "Phase '\(phase.name)' in \(mode.rawValue) should have sounds")
            }
        }
    }

    func test_allModes_haveSoundVolumesInValidRange() {
        for mode in AdaptiveMode.allCases {
            for phase in mode.phases {
                for (soundId, volume) in phase.sounds {
                    XCTAssertGreaterThanOrEqual(volume, 0, "Sound '\(soundId)' in phase '\(phase.name)' should have non-negative volume")
                    XCTAssertLessThanOrEqual(volume, 1, "Sound '\(soundId)' in phase '\(phase.name)' should have volume <= 1.0")
                }
            }
        }
    }

    func test_allModes_haveUniquePhaseNames() {
        for mode in AdaptiveMode.allCases {
            // focusSession has duplicate "Focus" names by design, skip it
            if mode == .focusSession { continue }

            let names = mode.phases.map { $0.name }
            let uniqueNames = Set(names)
            XCTAssertEqual(names.count, uniqueNames.count, "\(mode.rawValue) should have unique phase names")
        }
    }

    // MARK: - AdaptiveMode Enum Tests

    func test_allModes_haveNonEmptyLocalizedNames() {
        for mode in AdaptiveMode.allCases {
            XCTAssertFalse(mode.localizedName.isEmpty, "\(mode.rawValue) should have a localized name")
        }
    }

    func test_allModes_haveIcons() {
        for mode in AdaptiveMode.allCases {
            XCTAssertFalse(mode.icon.isEmpty, "\(mode.rawValue) should have an icon")
        }
    }

    func test_allModes_haveDescriptions() {
        for mode in AdaptiveMode.allCases {
            XCTAssertFalse(mode.description.isEmpty, "\(mode.rawValue) should have a description")
        }
    }

    func test_modeId_equalsRawValue() {
        for mode in AdaptiveMode.allCases {
            XCTAssertEqual(mode.id, mode.rawValue)
        }
    }

    // MARK: - AdaptivePhase Tests

    func test_adaptivePhase_initSetsProperties() {
        let phase = AdaptivePhase(name: "Test Phase", sounds: ["rain": 0.5], duration: 10)

        XCTAssertEqual(phase.name, "Test Phase")
        XCTAssertEqual(phase.sounds, ["rain": 0.5])
        XCTAssertEqual(phase.duration, 10)
    }

    func test_adaptivePhase_generatesUniqueIds() {
        let phase1 = AdaptivePhase(name: "Phase 1", sounds: [:], duration: 5)
        let phase2 = AdaptivePhase(name: "Phase 2", sounds: [:], duration: 5)

        XCTAssertNotEqual(phase1.id, phase2.id)
    }

    func test_adaptivePhase_equalityUsesId() {
        let phase1 = AdaptivePhase(name: "Same Name", sounds: ["rain": 0.5], duration: 10)
        let phase2 = AdaptivePhase(name: "Same Name", sounds: ["rain": 0.5], duration: 10)

        // Different instances have different UUIDs, so they should not be equal
        XCTAssertNotEqual(phase1, phase2)
    }

    // MARK: - Focus Session Specific Tests

    func test_focusSession_followsPomodoroPattern() {
        let phases = AdaptiveMode.focusSession.phases

        // Should alternate: Focus, Break, Focus, Break, Focus, Long Break
        XCTAssertEqual(phases[0].name, "Focus")
        XCTAssertEqual(phases[1].name, "Short Break")
        XCTAssertEqual(phases[2].name, "Focus")
        XCTAssertEqual(phases[3].name, "Short Break")
        XCTAssertEqual(phases[4].name, "Focus")
        XCTAssertEqual(phases[5].name, "Long Break")
    }

    func test_focusSession_focusPhasesAre25Minutes() {
        let phases = AdaptiveMode.focusSession.phases
        let focusPhases = phases.filter { $0.name == "Focus" }

        for phase in focusPhases {
            XCTAssertEqual(phase.duration, 25, "Focus phases should be 25 minutes")
        }
    }

    func test_focusSession_shortBreaksAre5Minutes() {
        let phases = AdaptiveMode.focusSession.phases
        let shortBreaks = phases.filter { $0.name == "Short Break" }

        for brk in shortBreaks {
            XCTAssertEqual(brk.duration, 5, "Short breaks should be 5 minutes")
        }
    }

    func test_focusSession_longBreakIs15Minutes() {
        let phases = AdaptiveMode.focusSession.phases
        let longBreak = phases.first { $0.name == "Long Break" }

        XCTAssertNotNil(longBreak)
        XCTAssertEqual(longBreak?.duration, 15)
    }
}
