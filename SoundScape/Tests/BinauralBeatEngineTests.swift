import XCTest
@testable import SoundScape

final class BinauralBeatEngineTests: XCTestCase {

    // MARK: - BrainwaveState Frequency Tests

    func test_deltaFrequency_returns2Hz() {
        XCTAssertEqual(BrainwaveState.delta.frequency, 2.0)
    }

    func test_thetaFrequency_returns6Hz() {
        XCTAssertEqual(BrainwaveState.theta.frequency, 6.0)
    }

    func test_alphaFrequency_returns10Hz() {
        XCTAssertEqual(BrainwaveState.alpha.frequency, 10.0)
    }

    func test_betaFrequency_returns20Hz() {
        XCTAssertEqual(BrainwaveState.beta.frequency, 20.0)
    }

    func test_gammaFrequency_returns40Hz() {
        XCTAssertEqual(BrainwaveState.gamma.frequency, 40.0)
    }

    // MARK: - Frequency Calculation Tests

    func test_rightFrequency_equalsLeftPlusBeat_forDelta() {
        let baseFrequency: Float = 200.0
        let beatFrequency = BrainwaveState.delta.frequency

        let rightFrequency = baseFrequency + beatFrequency

        XCTAssertEqual(rightFrequency, 202.0)
    }

    func test_rightFrequency_equalsLeftPlusBeat_forAlpha() {
        let baseFrequency: Float = 200.0
        let beatFrequency = BrainwaveState.alpha.frequency

        let rightFrequency = baseFrequency + beatFrequency

        XCTAssertEqual(rightFrequency, 210.0)
    }

    func test_rightFrequency_equalsLeftPlusBeat_forGamma() {
        let baseFrequency: Float = 400.0
        let beatFrequency = BrainwaveState.gamma.frequency

        let rightFrequency = baseFrequency + beatFrequency

        XCTAssertEqual(rightFrequency, 440.0)
    }

    // MARK: - Engine State Tests

    @MainActor
    func test_init_isNotPlaying() {
        let sut = BinauralBeatEngine()

        XCTAssertFalse(sut.isPlaying)
    }

    @MainActor
    func test_start_setsIsPlayingTrue() {
        let sut = BinauralBeatEngine()

        sut.start()

        XCTAssertTrue(sut.isPlaying)

        sut.stop()
    }

    @MainActor
    func test_stop_setsIsPlayingFalse() {
        let sut = BinauralBeatEngine()
        sut.start()

        sut.stop()

        XCTAssertFalse(sut.isPlaying)
    }

    @MainActor
    func test_toggle_startsWhenNotPlaying() {
        let sut = BinauralBeatEngine()

        sut.toggle()

        XCTAssertTrue(sut.isPlaying)

        sut.stop()
    }

    @MainActor
    func test_toggle_stopsWhenPlaying() {
        let sut = BinauralBeatEngine()
        sut.start()

        sut.toggle()

        XCTAssertFalse(sut.isPlaying)
    }

    // MARK: - Volume Tests

    @MainActor
    func test_volume_defaultValue() {
        let sut = BinauralBeatEngine()

        XCTAssertEqual(sut.volume, 0.5)
    }

    @MainActor
    func test_volume_canBeSet() {
        let sut = BinauralBeatEngine()

        sut.volume = 0.8

        XCTAssertEqual(sut.volume, 0.8)
    }

    // MARK: - Base Frequency Tests

    func test_baseFrequencyLow_is200Hz() {
        XCTAssertEqual(BaseFrequency.low.rawValue, 200.0)
    }

    func test_baseFrequencyMedium_is300Hz() {
        XCTAssertEqual(BaseFrequency.medium.rawValue, 300.0)
    }

    func test_baseFrequencyHigh_is400Hz() {
        XCTAssertEqual(BaseFrequency.high.rawValue, 400.0)
    }

    // MARK: - Tone Type Tests

    func test_toneTypes_allCases() {
        XCTAssertEqual(ToneType.allCases.count, 2)
        XCTAssertTrue(ToneType.allCases.contains(.binaural))
        XCTAssertTrue(ToneType.allCases.contains(.isochronic))
    }

    // MARK: - BrainwaveState Tests

    func test_brainwaveStates_allCases() {
        XCTAssertEqual(BrainwaveState.allCases.count, 5)
        XCTAssertTrue(BrainwaveState.allCases.contains(.delta))
        XCTAssertTrue(BrainwaveState.allCases.contains(.theta))
        XCTAssertTrue(BrainwaveState.allCases.contains(.alpha))
        XCTAssertTrue(BrainwaveState.allCases.contains(.beta))
        XCTAssertTrue(BrainwaveState.allCases.contains(.gamma))
    }

    func test_brainwaveState_descriptions() {
        XCTAssertEqual(BrainwaveState.delta.description, "Deep Sleep")
        XCTAssertEqual(BrainwaveState.theta.description, "Meditation")
        XCTAssertEqual(BrainwaveState.alpha.description, "Relaxation")
        XCTAssertEqual(BrainwaveState.beta.description, "Focus")
        XCTAssertEqual(BrainwaveState.gamma.description, "Creativity")
    }

    // MARK: - Start/Stop Edge Cases

    @MainActor
    func test_start_whenAlreadyPlaying_doesNotCrash() {
        let sut = BinauralBeatEngine()
        sut.start()

        sut.start()

        XCTAssertTrue(sut.isPlaying)

        sut.stop()
    }

    @MainActor
    func test_stop_whenNotPlaying_doesNotCrash() {
        let sut = BinauralBeatEngine()

        sut.stop()

        XCTAssertFalse(sut.isPlaying)
    }
}
