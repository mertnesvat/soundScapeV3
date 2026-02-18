import XCTest
@testable import SoundScape

final class SoundEventDetectorTests: XCTestCase {

    private var sut: SoundEventDetector!

    override func setUp() {
        super.setUp()
        sut = SoundEventDetector()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Empty / Edge Case Tests

    func test_analyze_emptySamples_returnsNoEvents() {
        let result = sut.analyze(samples: [], recordingDuration: 0, startDate: Date())

        XCTAssertTrue(result.events.isEmpty)
        XCTAssertEqual(result.snoreScore, 0)
    }

    func test_analyze_tooFewSamples_returnsNoEvents() {
        let result = sut.analyze(samples: [30, 30, 30], recordingDuration: 3, startDate: Date())

        XCTAssertTrue(result.events.isEmpty)
        XCTAssertEqual(result.snoreScore, 0)
    }

    func test_analyze_allSilence_returnsOnlySilenceEvent() {
        // 600 samples at baseline level (10 minutes)
        let samples = Array(repeating: Float(30), count: 600)
        let result = sut.analyze(samples: samples, recordingDuration: 600, startDate: Date())

        let silenceEvents = result.events.filter { $0.type == .silence }
        XCTAssertFalse(silenceEvents.isEmpty, "Should detect at least one silence period")
        XCTAssertEqual(result.snoreScore, 0, "Score should be 0 with no snoring")
    }

    // MARK: - Snoring Detection Tests

    func test_analyze_snoringPattern_detectsSnoring() {
        // Create a rhythmic pattern: elevated for 3+ seconds with peaks and valleys
        var samples = Array(repeating: Float(30), count: 100) // baseline
        // Add rhythmic snoring pattern: alternating high/low above baseline
        for i in 20..<35 {
            samples[i] = i % 2 == 0 ? 45 : 38 // 8+ dB above baseline with rhythm
        }

        let result = sut.analyze(samples: samples, recordingDuration: 100, startDate: Date())

        let snoringEvents = result.events.filter { $0.type == .snoring }
        XCTAssertFalse(snoringEvents.isEmpty, "Should detect snoring from rhythmic elevated pattern")
    }

    // MARK: - Loud Sound Detection Tests

    func test_analyze_loudSpike_detectsLoudSound() {
        var samples = Array(repeating: Float(30), count: 100) // baseline
        // Single loud spike: 20+ dB above baseline
        samples[50] = 55

        let result = sut.analyze(samples: samples, recordingDuration: 100, startDate: Date())

        let loudEvents = result.events.filter { $0.type == .loudSound }
        XCTAssertFalse(loudEvents.isEmpty, "Should detect loud sound from spike")
        if let first = loudEvents.first {
            XCTAssertEqual(first.peakDecibels, 55.0, accuracy: 0.1)
        }
    }

    func test_analyze_multipleLoudSpikes_detectsMultipleEvents() {
        var samples = Array(repeating: Float(30), count: 200) // baseline
        samples[50] = 55
        samples[150] = 58

        let result = sut.analyze(samples: samples, recordingDuration: 200, startDate: Date())

        let loudEvents = result.events.filter { $0.type == .loudSound }
        XCTAssertGreaterThanOrEqual(loudEvents.count, 2, "Should detect multiple loud sounds")
    }

    // MARK: - Silence Detection Tests

    func test_analyze_extendedQuiet_detectsSilence() {
        // 600 seconds all at baseline = 10 minutes silence
        let samples = Array(repeating: Float(30), count: 600)
        let result = sut.analyze(samples: samples, recordingDuration: 600, startDate: Date())

        let silenceEvents = result.events.filter { $0.type == .silence }
        XCTAssertFalse(silenceEvents.isEmpty, "Should detect extended silence")
        if let first = silenceEvents.first {
            XCTAssertGreaterThanOrEqual(first.duration, 300, "Silence should be 5+ minutes")
        }
    }

    func test_analyze_shortQuiet_noSilenceEvent() {
        // 100 seconds at baseline - not long enough for silence event (need 300+)
        let samples = Array(repeating: Float(30), count: 100)
        let result = sut.analyze(samples: samples, recordingDuration: 100, startDate: Date())

        let silenceEvents = result.events.filter { $0.type == .silence }
        XCTAssertTrue(silenceEvents.isEmpty, "Should not detect silence for short periods")
    }

    // MARK: - Event Merging Tests

    func test_analyze_adjacentSameTypeEvents_areMerged() {
        var samples = Array(repeating: Float(30), count: 200) // baseline
        // Two loud bursts 3 seconds apart (within 5-second merge threshold)
        samples[50] = 55
        samples[53] = 56

        let result = sut.analyze(samples: samples, recordingDuration: 200, startDate: Date())

        let loudEvents = result.events.filter { $0.type == .loudSound }
        XCTAssertEqual(loudEvents.count, 1, "Adjacent same-type events within 5s should be merged")
    }

    func test_analyze_distantSameTypeEvents_notMerged() {
        var samples = Array(repeating: Float(30), count: 200) // baseline
        // Two loud bursts 50 seconds apart
        samples[50] = 55
        samples[100] = 56

        let result = sut.analyze(samples: samples, recordingDuration: 200, startDate: Date())

        let loudEvents = result.events.filter { $0.type == .loudSound }
        XCTAssertGreaterThanOrEqual(loudEvents.count, 2, "Distant events should not be merged")
    }

    // MARK: - Snore Score Tests

    func test_snoreScore_noSnoring_returnsZero() {
        let samples = Array(repeating: Float(30), count: 600) // all baseline
        let result = sut.analyze(samples: samples, recordingDuration: 600, startDate: Date())

        XCTAssertEqual(result.snoreScore, 0)
    }

    func test_snoreScore_heavySnoring_returnsHighScore() {
        var samples = Array(repeating: Float(30), count: 1000) // baseline
        // Add lots of snoring: 30% of the recording
        for i in stride(from: 100, to: 400, by: 1) {
            samples[i] = i % 2 == 0 ? 50 : 42 // rhythmic pattern, well above baseline
        }

        let result = sut.analyze(samples: samples, recordingDuration: 1000, startDate: Date())

        XCTAssertGreaterThan(result.snoreScore, 30, "Heavy snoring should produce high score")
    }

    func test_snoreScore_clampedTo100() {
        // Even with extreme values, score should not exceed 100
        var samples = Array(repeating: Float(30), count: 100) // baseline
        for i in 10..<90 {
            samples[i] = i % 2 == 0 ? 80 : 55
        }

        let result = sut.analyze(samples: samples, recordingDuration: 100, startDate: Date())

        XCTAssertLessThanOrEqual(result.snoreScore, 100)
        XCTAssertGreaterThanOrEqual(result.snoreScore, 0)
    }

    // MARK: - Realistic Scenario Tests

    func test_analyze_realisticNight_detectsMultipleEventTypes() {
        // Simulate 30-minute recording (1800 samples)
        var samples = Array(repeating: Float(30), count: 1800) // baseline

        // Snoring episode at 10 minutes (600-620)
        for i in 600..<620 {
            samples[i] = i % 2 == 0 ? 45 : 38
        }

        // Loud sound at 15 minutes
        samples[900] = 60
        samples[901] = 55

        // Quiet period: first 5 minutes are already baseline (300 samples)

        let result = sut.analyze(samples: samples, recordingDuration: 1800, startDate: Date())

        XCTAssertFalse(result.events.isEmpty, "Should detect events in realistic scenario")

        let types = Set(result.events.map(\.type))
        XCTAssertTrue(types.count >= 2, "Should detect at least 2 different event types")
    }
}
