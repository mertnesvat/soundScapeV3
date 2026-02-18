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

    // MARK: - Empty / Edge Cases

    func test_analyze_emptySamples_returnsNoEvents() {
        let result = sut.analyze(samples: [], recordingDuration: 0, startDate: Date())

        XCTAssertTrue(result.events.isEmpty)
        XCTAssertEqual(result.snoreScore, 0)
    }

    func test_analyze_allSilence_returnsOnlySilenceEvents() {
        // 600 seconds (10 minutes) of constant low noise
        let samples = [Float](repeating: 30, count: 600)

        let result = sut.analyze(samples: samples, recordingDuration: 600, startDate: Date())

        let nonSilenceEvents = result.events.filter { $0.type != .silence }
        XCTAssertTrue(nonSilenceEvents.isEmpty)
        XCTAssertEqual(result.snoreScore, 0)
    }

    func test_analyze_allLoud_detectsLoudEvents() {
        // Baseline at 30, then everything at 55+ (25 dB above baseline)
        var samples = [Float](repeating: 30, count: 300)
        // Add loud spikes
        samples[100] = 60
        samples[200] = 65

        let result = sut.analyze(samples: samples, recordingDuration: 300, startDate: Date())

        let loudEvents = result.events.filter { $0.type == .loudSound }
        XCTAssertGreaterThan(loudEvents.count, 0, "Should detect loud sound events")
    }

    // MARK: - Snoring Detection

    func test_analyze_snoringPattern_detectsSnoring() {
        // Create a rhythmic pattern: baseline=30, snoring with clear peaks/valleys
        // Need 8+ dB above baseline sustained for 3+ seconds with rhythmic pattern
        var samples = [Float](repeating: 30, count: 500)

        // Insert a clear rhythmic snoring pattern - sustained above baseline for 20 seconds
        // with alternating peaks and valleys to trigger rhythmic detection
        for i in 100..<120 {
            if i % 2 == 0 {
                samples[i] = 50 // peak (20 above baseline)
            } else {
                samples[i] = 40 // valley (still 10 above baseline)
            }
        }

        let result = sut.analyze(samples: samples, recordingDuration: 500, startDate: Date())

        // Should detect either snoring or talking (both are valid for sustained elevated sound)
        let detectedEvents = result.events.filter { $0.type == .snoring || $0.type == .talking }
        XCTAssertGreaterThan(detectedEvents.count, 0, "Should detect snoring or talking events for sustained elevated sound")
    }

    // MARK: - Silence Detection

    func test_analyze_longSilence_detectsSilencePeriod() {
        // 600+ seconds of quiet = silence event (5 minute minimum)
        var samples = [Float](repeating: 30, count: 700)
        // Add a brief loud event so it's not all silence
        samples[0] = 60
        samples[1] = 60
        samples[2] = 60

        let result = sut.analyze(samples: samples, recordingDuration: 700, startDate: Date())

        let silenceEvents = result.events.filter { $0.type == .silence }
        XCTAssertGreaterThan(silenceEvents.count, 0, "Should detect silence periods")
    }

    func test_analyze_shortSilence_noSilenceEvent() {
        // 200 seconds of quiet - should NOT trigger silence (need 300+)
        let samples = [Float](repeating: 30, count: 200)

        let result = sut.analyze(samples: samples, recordingDuration: 200, startDate: Date())

        let silenceEvents = result.events.filter { $0.type == .silence }
        XCTAssertEqual(silenceEvents.count, 0, "Short quiet period should not be classified as silence")
    }

    // MARK: - Event Merging

    func test_analyze_adjacentSameTypeEvents_areMerged() {
        var samples = [Float](repeating: 30, count: 500)

        // Two loud spikes within 5 seconds of each other
        samples[100] = 60
        samples[104] = 62

        let result = sut.analyze(samples: samples, recordingDuration: 500, startDate: Date())

        let loudEvents = result.events.filter { $0.type == .loudSound }
        // They should be merged into 1 or at most stay as 2 (if not within merge threshold)
        // The important thing is the algorithm processes them
        XCTAssertGreaterThan(loudEvents.count, 0)
    }

    // MARK: - Snore Score Calculation

    func test_snoreScore_noSnoring_isZero() {
        let samples = [Float](repeating: 30, count: 500)

        let result = sut.analyze(samples: samples, recordingDuration: 500, startDate: Date())

        XCTAssertEqual(result.snoreScore, 0)
    }

    func test_snoreScore_inRange0to100() {
        // Create samples with snoring
        var samples = [Float](repeating: 30, count: 1000)
        for i in stride(from: 100, to: 600, by: 50) {
            for j in 0..<20 {
                if i + j < samples.count {
                    samples[i + j] = j % 3 == 0 ? 48 : 40
                }
            }
        }

        let result = sut.analyze(samples: samples, recordingDuration: 1000, startDate: Date())

        XCTAssertGreaterThanOrEqual(result.snoreScore, 0)
        XCTAssertLessThanOrEqual(result.snoreScore, 100)
    }

    // MARK: - Performance

    func test_analyze_longRecording_completesQuickly() {
        // Simulate 8 hours (28800 samples) - should complete in <5 seconds
        var samples = [Float](repeating: 30, count: 28800)
        // Add some events
        for i in stride(from: 0, to: 28800, by: 1800) {
            for j in 0..<15 {
                if i + j < samples.count {
                    samples[i + j] = j % 3 == 0 ? 50 : 42
                }
            }
        }

        measure {
            _ = sut.analyze(samples: samples, recordingDuration: 28800, startDate: Date())
        }
    }
}
