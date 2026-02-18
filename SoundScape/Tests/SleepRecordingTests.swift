import XCTest
@testable import SoundScape

final class SleepRecordingTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeSleepRecording(
        duration: TimeInterval = 7 * 3600 + 32 * 60,
        events: [SoundEvent] = [],
        snoreScore: Int = 45
    ) -> SleepRecording {
        SleepRecording(
            date: Date(timeIntervalSince1970: 1_000_000),
            endDate: Date(timeIntervalSince1970: 1_000_000 + duration),
            duration: duration,
            fileURL: URL(fileURLWithPath: "/tmp/test.m4a"),
            events: events,
            decibelSamples: [30, 32, 35, 40, 38],
            averageDecibels: 35,
            peakDecibels: 72,
            snoreScore: snoreScore
        )
    }

    private func makeSoundEvent(
        timestamp: TimeInterval = 3600,
        duration: TimeInterval = 12,
        type: SoundEventType = .snoring,
        peakDecibels: Float = 54,
        averageDecibels: Float = 48
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
            makeSoundEvent(type: .snoring),
            makeSoundEvent(timestamp: 7200, type: .loudSound, peakDecibels: 72),
        ]
        let original = makeSleepRecording(events: events)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SleepRecording.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.duration, original.duration)
        XCTAssertEqual(decoded.snoreScore, original.snoreScore)
        XCTAssertEqual(decoded.events.count, original.events.count)
        XCTAssertEqual(decoded.decibelSamples, original.decibelSamples)
        XCTAssertEqual(decoded.averageDecibels, original.averageDecibels)
        XCTAssertEqual(decoded.peakDecibels, original.peakDecibels)
    }

    // MARK: - formattedDuration Tests

    func test_formattedDuration_hoursAndMinutes() {
        let recording = makeSleepRecording(duration: 7 * 3600 + 32 * 60)
        XCTAssertEqual(recording.formattedDuration, "7h 32m")
    }

    func test_formattedDuration_minutesOnly() {
        let recording = makeSleepRecording(duration: 45 * 60)
        XCTAssertEqual(recording.formattedDuration, "45m")
    }

    func test_formattedDuration_zeroMinutes() {
        let recording = makeSleepRecording(duration: 3600)
        XCTAssertEqual(recording.formattedDuration, "1h 0m")
    }

    // MARK: - snoringMinutes Tests

    func test_snoringMinutes_calculatesCorrectly() {
        let events = [
            makeSoundEvent(duration: 120, type: .snoring),
            makeSoundEvent(duration: 180, type: .snoring),
            makeSoundEvent(duration: 60, type: .loudSound),
        ]
        let recording = makeSleepRecording(events: events)

        XCTAssertEqual(recording.snoringMinutes, 5.0, accuracy: 0.01)
    }

    func test_snoringMinutes_noSnoringEvents() {
        let events = [
            makeSoundEvent(type: .loudSound),
            makeSoundEvent(type: .silence),
        ]
        let recording = makeSleepRecording(events: events)

        XCTAssertEqual(recording.snoringMinutes, 0.0)
    }

    // MARK: - snoreScoreCategory Tests

    func test_snoreScoreCategory_quiet() {
        let recording = makeSleepRecording(snoreScore: 0)
        XCTAssertEqual(recording.snoreScoreCategory, "Quiet")

        let recording2 = makeSleepRecording(snoreScore: 30)
        XCTAssertEqual(recording2.snoreScoreCategory, "Quiet")
    }

    func test_snoreScoreCategory_moderate() {
        let recording = makeSleepRecording(snoreScore: 31)
        XCTAssertEqual(recording.snoreScoreCategory, "Moderate")

        let recording2 = makeSleepRecording(snoreScore: 60)
        XCTAssertEqual(recording2.snoreScoreCategory, "Moderate")
    }

    func test_snoreScoreCategory_loud() {
        let recording = makeSleepRecording(snoreScore: 61)
        XCTAssertEqual(recording.snoreScoreCategory, "Loud")

        let recording2 = makeSleepRecording(snoreScore: 100)
        XCTAssertEqual(recording2.snoreScoreCategory, "Loud")
    }

    // MARK: - eventCount Tests

    func test_eventCount_returnsCorrectCount() {
        let events = [
            makeSoundEvent(type: .snoring),
            makeSoundEvent(type: .loudSound),
            makeSoundEvent(type: .talking),
        ]
        let recording = makeSleepRecording(events: events)

        XCTAssertEqual(recording.eventCount, 3)
    }

    func test_eventCount_emptyEvents() {
        let recording = makeSleepRecording()
        XCTAssertEqual(recording.eventCount, 0)
    }

    // MARK: - SoundEvent Tests

    func test_soundEvent_encodeDecode() throws {
        let original = makeSoundEvent()

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SoundEvent.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.timestamp, original.timestamp)
        XCTAssertEqual(decoded.duration, original.duration)
        XCTAssertEqual(decoded.type, original.type)
        XCTAssertEqual(decoded.peakDecibels, original.peakDecibels)
        XCTAssertEqual(decoded.averageDecibels, original.averageDecibels)
    }

    func test_soundEvent_formattedDuration_seconds() {
        let event = makeSoundEvent(duration: 12)
        XCTAssertEqual(event.formattedDuration, "12s")
    }

    func test_soundEvent_formattedDuration_minutes() {
        let event = makeSoundEvent(duration: 120)
        XCTAssertEqual(event.formattedDuration, "2m")
    }

    func test_soundEvent_formattedDuration_minutesAndSeconds() {
        let event = makeSoundEvent(duration: 75)
        XCTAssertEqual(event.formattedDuration, "1m 15s")
    }

    // MARK: - SoundEventType Tests

    func test_soundEventType_allCases() {
        XCTAssertEqual(SoundEventType.allCases.count, 4)
        XCTAssertTrue(SoundEventType.allCases.contains(.snoring))
        XCTAssertTrue(SoundEventType.allCases.contains(.loudSound))
        XCTAssertTrue(SoundEventType.allCases.contains(.talking))
        XCTAssertTrue(SoundEventType.allCases.contains(.silence))
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
        XCTAssertEqual(SoundEventType.talking.icon, "mouth.fill")
        XCTAssertEqual(SoundEventType.silence.icon, "speaker.slash.fill")
    }

    func test_soundEventType_encodeDecode() throws {
        for eventType in SoundEventType.allCases {
            let data = try JSONEncoder().encode(eventType)
            let decoded = try JSONDecoder().decode(SoundEventType.self, from: data)
            XCTAssertEqual(decoded, eventType)
        }
    }

    // MARK: - formattedDate Tests

    func test_formattedDate_isNotEmpty() {
        let recording = makeSleepRecording()
        XCTAssertFalse(recording.formattedDate.isEmpty)
    }

    // MARK: - formattedTimeRange Tests

    func test_formattedTimeRange_containsDash() {
        let recording = makeSleepRecording()
        XCTAssertTrue(recording.formattedTimeRange.contains("-"))
    }
}
