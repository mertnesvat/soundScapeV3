import XCTest
@testable import SoundScape

final class SleepRecordingTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeRecording(
        duration: TimeInterval = 27000, // 7.5 hours
        events: [SoundEvent] = [],
        decibelSamples: [Float] = [],
        snoreScore: Int = 0
    ) -> SleepRecording {
        let start = Date()
        return SleepRecording(
            date: start,
            endDate: start.addingTimeInterval(duration),
            duration: duration,
            fileURL: URL(fileURLWithPath: "/tmp/test_recording.m4a"),
            events: events,
            decibelSamples: decibelSamples,
            averageDecibels: 35,
            peakDecibels: 72,
            snoreScore: snoreScore
        )
    }

    private func makeEvent(
        type: SoundEventType = .snoring,
        timestamp: TimeInterval = 3600,
        duration: TimeInterval = 10,
        peakDecibels: Float = 60,
        averageDecibels: Float = 50
    ) -> SoundEvent {
        SoundEvent(
            timestamp: timestamp,
            duration: duration,
            type: type,
            peakDecibels: peakDecibels,
            averageDecibels: averageDecibels
        )
    }

    // MARK: - SleepRecording Codable Tests

    func test_sleepRecording_encodeDecode() throws {
        let events = [
            makeEvent(type: .snoring, timestamp: 3600, duration: 15),
            makeEvent(type: .loudSound, timestamp: 7200, duration: 3)
        ]
        let original = makeRecording(events: events, decibelSamples: [30, 35, 40, 55, 32], snoreScore: 45)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(SleepRecording.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.duration, original.duration)
        XCTAssertEqual(decoded.events.count, original.events.count)
        XCTAssertEqual(decoded.decibelSamples, original.decibelSamples)
        XCTAssertEqual(decoded.snoreScore, original.snoreScore)
        XCTAssertEqual(decoded.averageDecibels, original.averageDecibels)
        XCTAssertEqual(decoded.peakDecibels, original.peakDecibels)
    }

    // MARK: - formattedDuration Tests

    func test_formattedDuration_hoursAndMinutes() {
        let recording = makeRecording(duration: 27120) // 7h 32m

        XCTAssertEqual(recording.formattedDuration, "7h 32m")
    }

    func test_formattedDuration_minutesOnly() {
        let recording = makeRecording(duration: 2700) // 45m

        XCTAssertEqual(recording.formattedDuration, "45m")
    }

    func test_formattedDuration_exactHours() {
        let recording = makeRecording(duration: 28800) // 8h 0m

        XCTAssertEqual(recording.formattedDuration, "8h 0m")
    }

    func test_formattedDuration_oneMinute() {
        let recording = makeRecording(duration: 60)

        XCTAssertEqual(recording.formattedDuration, "1m")
    }

    // MARK: - snoringMinutes Tests

    func test_snoringMinutes_noEvents() {
        let recording = makeRecording()

        XCTAssertEqual(recording.snoringMinutes, 0)
    }

    func test_snoringMinutes_withSnoringEvents() {
        let events = [
            makeEvent(type: .snoring, duration: 120), // 2 min
            makeEvent(type: .snoring, duration: 180), // 3 min
            makeEvent(type: .loudSound, duration: 60) // should not count
        ]
        let recording = makeRecording(events: events)

        XCTAssertEqual(recording.snoringMinutes, 5.0, accuracy: 0.01)
    }

    func test_snoringMinutes_onlyNonSnoringEvents() {
        let events = [
            makeEvent(type: .loudSound, duration: 60),
            makeEvent(type: .talking, duration: 30),
            makeEvent(type: .silence, duration: 300)
        ]
        let recording = makeRecording(events: events)

        XCTAssertEqual(recording.snoringMinutes, 0)
    }

    // MARK: - eventCount Tests

    func test_eventCount_excludesSilence() {
        let events = [
            makeEvent(type: .snoring),
            makeEvent(type: .loudSound),
            makeEvent(type: .silence),
            makeEvent(type: .talking)
        ]
        let recording = makeRecording(events: events)

        XCTAssertEqual(recording.eventCount, 3)
    }

    func test_eventCount_allSilence() {
        let events = [
            makeEvent(type: .silence),
            makeEvent(type: .silence)
        ]
        let recording = makeRecording(events: events)

        XCTAssertEqual(recording.eventCount, 0)
    }

    // MARK: - snoreScoreCategory Tests

    func test_snoreScoreCategory_quiet() {
        XCTAssertEqual(makeRecording(snoreScore: 0).snoreScoreCategory, .quiet)
        XCTAssertEqual(makeRecording(snoreScore: 15).snoreScoreCategory, .quiet)
        XCTAssertEqual(makeRecording(snoreScore: 30).snoreScoreCategory, .quiet)
    }

    func test_snoreScoreCategory_moderate() {
        XCTAssertEqual(makeRecording(snoreScore: 31).snoreScoreCategory, .moderate)
        XCTAssertEqual(makeRecording(snoreScore: 45).snoreScoreCategory, .moderate)
        XCTAssertEqual(makeRecording(snoreScore: 60).snoreScoreCategory, .moderate)
    }

    func test_snoreScoreCategory_loud() {
        XCTAssertEqual(makeRecording(snoreScore: 61).snoreScoreCategory, .loud)
        XCTAssertEqual(makeRecording(snoreScore: 80).snoreScoreCategory, .loud)
        XCTAssertEqual(makeRecording(snoreScore: 100).snoreScoreCategory, .loud)
    }

    // MARK: - SoundEvent Tests

    func test_soundEvent_formattedDuration_seconds() {
        let event = makeEvent(duration: 12)

        XCTAssertEqual(event.formattedDuration, "12s")
    }

    func test_soundEvent_formattedDuration_minutesAndSeconds() {
        let event = makeEvent(duration: 95) // 1m 35s

        XCTAssertEqual(event.formattedDuration, "1m 35s")
    }

    func test_soundEvent_formattedDuration_exactMinutes() {
        let event = makeEvent(duration: 120)

        XCTAssertEqual(event.formattedDuration, "2m")
    }

    func test_soundEvent_encodeDecode() throws {
        let original = makeEvent(type: .snoring, timestamp: 3661, duration: 15, peakDecibels: 65, averageDecibels: 55)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SoundEvent.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.type, original.type)
        XCTAssertEqual(decoded.timestamp, original.timestamp)
        XCTAssertEqual(decoded.duration, original.duration)
        XCTAssertEqual(decoded.peakDecibels, original.peakDecibels)
        XCTAssertEqual(decoded.averageDecibels, original.averageDecibels)
    }

    // MARK: - SoundEventType Tests

    func test_soundEventType_allCases() {
        let allCases = SoundEventType.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.snoring))
        XCTAssertTrue(allCases.contains(.loudSound))
        XCTAssertTrue(allCases.contains(.talking))
        XCTAssertTrue(allCases.contains(.silence))
    }

    func test_soundEventType_displayNames() {
        XCTAssertFalse(SoundEventType.snoring.displayName.isEmpty)
        XCTAssertFalse(SoundEventType.loudSound.displayName.isEmpty)
        XCTAssertFalse(SoundEventType.talking.displayName.isEmpty)
        XCTAssertFalse(SoundEventType.silence.displayName.isEmpty)
    }

    func test_soundEventType_icons() {
        XCTAssertEqual(SoundEventType.snoring.icon, "zzz")
        XCTAssertEqual(SoundEventType.loudSound.icon, "speaker.wave.3.fill")
        XCTAssertEqual(SoundEventType.talking.icon, "person.wave.2.fill")
        XCTAssertEqual(SoundEventType.silence.icon, "moon.zzz.fill")
    }

    func test_soundEventType_encodeDecode() throws {
        for type in SoundEventType.allCases {
            let data = try JSONEncoder().encode(type)
            let decoded = try JSONDecoder().decode(SoundEventType.self, from: data)
            XCTAssertEqual(decoded, type)
        }
    }

    // MARK: - RecordingStatus Tests

    func test_recordingStatus_encodeDecode() throws {
        let statuses: [RecordingStatus] = [.idle, .recording, .analyzing, .complete]
        for status in statuses {
            let data = try JSONEncoder().encode(status)
            let decoded = try JSONDecoder().decode(RecordingStatus.self, from: data)
            XCTAssertEqual(decoded, status)
        }
    }

    // MARK: - Default Values

    func test_sleepRecording_defaultValues() {
        let recording = SleepRecording()

        XCTAssertEqual(recording.duration, 0)
        XCTAssertTrue(recording.events.isEmpty)
        XCTAssertTrue(recording.decibelSamples.isEmpty)
        XCTAssertEqual(recording.averageDecibels, 0)
        XCTAssertEqual(recording.peakDecibels, 0)
        XCTAssertEqual(recording.snoreScore, 0)
    }

    // MARK: - formattedDuration Edge Cases

    func test_formattedDuration_zeroDuration() {
        let recording = makeRecording(duration: 0)

        XCTAssertEqual(recording.formattedDuration, "0m")
    }

    func test_formattedDuration_lessThanOneMinute() {
        let recording = makeRecording(duration: 30) // 30 seconds

        XCTAssertEqual(recording.formattedDuration, "0m")
    }

    // MARK: - formattedDate Tests

    func test_formattedDate_returnsNonEmptyString() {
        let recording = makeRecording()

        XCTAssertFalse(recording.formattedDate.isEmpty)
    }

    // MARK: - formattedTimeRange Tests

    func test_formattedTimeRange_returnsRangeWithDash() {
        let recording = makeRecording(duration: 3600) // 1 hour

        let range = recording.formattedTimeRange
        XCTAssertTrue(range.contains("-"), "Time range should contain a dash separator")
    }

    // MARK: - SoundEvent formattedTimestamp Tests

    func test_soundEvent_formattedTimestamp_returnsNonEmpty() {
        let event = makeEvent(timestamp: 7200) // 2 hours in

        XCTAssertFalse(event.formattedTimestamp.isEmpty)
    }

    func test_soundEvent_formattedDuration_zeroSeconds() {
        let event = makeEvent(duration: 0)

        XCTAssertEqual(event.formattedDuration, "0s")
    }

    // MARK: - SnoreScoreCategory Tests

    func test_snoreScoreCategory_displayNames_notEmpty() {
        for category in [SnoreScoreCategory.quiet, .moderate, .loud] {
            XCTAssertFalse(category.displayName.isEmpty)
        }
    }

    func test_snoreScoreCategory_colors_areDifferent() {
        let quiet = SnoreScoreCategory.quiet.color
        let moderate = SnoreScoreCategory.moderate.color
        let loud = SnoreScoreCategory.loud.color

        XCTAssertNotEqual(quiet, moderate)
        XCTAssertNotEqual(moderate, loud)
        XCTAssertNotEqual(quiet, loud)
    }

    // MARK: - SoundEventType Color Tests

    func test_soundEventType_colors_areDifferent() {
        let colors = SoundEventType.allCases.map { $0.color }
        // All 4 types should have distinct colors
        for i in 0..<colors.count {
            for j in (i + 1)..<colors.count {
                XCTAssertNotEqual(colors[i], colors[j], "Colors for \(SoundEventType.allCases[i]) and \(SoundEventType.allCases[j]) should differ")
            }
        }
    }

    // MARK: - Boundary Score Tests

    func test_snoreScoreCategory_boundaryValues() {
        // Exact boundary at 30
        XCTAssertEqual(makeRecording(snoreScore: 30).snoreScoreCategory, .quiet)
        // Exact boundary at 31
        XCTAssertEqual(makeRecording(snoreScore: 31).snoreScoreCategory, .moderate)
        // Exact boundary at 60
        XCTAssertEqual(makeRecording(snoreScore: 60).snoreScoreCategory, .moderate)
        // Exact boundary at 61
        XCTAssertEqual(makeRecording(snoreScore: 61).snoreScoreCategory, .loud)
    }

    // MARK: - Multiple Snoring Events Duration

    func test_snoringMinutes_fractionalMinutes() {
        let events = [
            makeEvent(type: .snoring, duration: 90) // 1.5 minutes
        ]
        let recording = makeRecording(events: events)

        XCTAssertEqual(recording.snoringMinutes, 1.5, accuracy: 0.01)
    }

    // MARK: - Event Count Edge Cases

    func test_eventCount_noEvents() {
        let recording = makeRecording(events: [])

        XCTAssertEqual(recording.eventCount, 0)
    }

    func test_eventCount_mixedWithMultipleSilence() {
        let events = [
            makeEvent(type: .snoring),
            makeEvent(type: .silence),
            makeEvent(type: .silence),
            makeEvent(type: .silence),
            makeEvent(type: .talking)
        ]
        let recording = makeRecording(events: events)

        XCTAssertEqual(recording.eventCount, 2) // only snoring + talking
    }
}
