import XCTest
@testable import SoundScape

final class SleepRecordingTests: XCTestCase {

    // MARK: - Codable Round-Trip

    func test_sleepRecording_encodeDecode() throws {
        let event = SoundEvent(
            timestamp: 3600,
            duration: 12,
            type: .snoring,
            peakDecibels: 65,
            averageDecibels: 52
        )
        let recording = SleepRecording(
            date: Date(timeIntervalSince1970: 1000000),
            endDate: Date(timeIntervalSince1970: 1027200),
            duration: 27200,
            fileURL: URL(fileURLWithPath: "/tmp/test.m4a"),
            events: [event],
            decibelSamples: [30.0, 35.0, 40.0],
            averageDecibels: 35.0,
            peakDecibels: 65.0,
            snoreScore: 45
        )

        let data = try JSONEncoder().encode(recording)
        let decoded = try JSONDecoder().decode(SleepRecording.self, from: data)

        XCTAssertEqual(decoded.id, recording.id)
        XCTAssertEqual(decoded.date, recording.date)
        XCTAssertEqual(decoded.endDate, recording.endDate)
        XCTAssertEqual(decoded.duration, recording.duration)
        XCTAssertEqual(decoded.fileURL, recording.fileURL)
        XCTAssertEqual(decoded.events.count, 1)
        XCTAssertEqual(decoded.decibelSamples, [30.0, 35.0, 40.0])
        XCTAssertEqual(decoded.averageDecibels, 35.0)
        XCTAssertEqual(decoded.peakDecibels, 65.0)
        XCTAssertEqual(decoded.snoreScore, 45)
    }

    func test_soundEvent_encodeDecode() throws {
        let event = SoundEvent(
            timestamp: 7200,
            duration: 8.5,
            type: .loudSound,
            peakDecibels: 78,
            averageDecibels: 62
        )

        let data = try JSONEncoder().encode(event)
        let decoded = try JSONDecoder().decode(SoundEvent.self, from: data)

        XCTAssertEqual(decoded.id, event.id)
        XCTAssertEqual(decoded.timestamp, 7200)
        XCTAssertEqual(decoded.duration, 8.5)
        XCTAssertEqual(decoded.type, .loudSound)
        XCTAssertEqual(decoded.peakDecibels, 78)
        XCTAssertEqual(decoded.averageDecibels, 62)
    }

    func test_recordingStatus_encodeDecode() throws {
        let statuses: [RecordingStatus] = [.idle, .recording, .analyzing, .complete]
        for status in statuses {
            let data = try JSONEncoder().encode(status)
            let decoded = try JSONDecoder().decode(RecordingStatus.self, from: data)
            XCTAssertEqual(decoded, status)
        }
    }

    // MARK: - Formatted Duration

    func test_formattedDuration_hoursAndMinutes() {
        let recording = makeRecording(duration: 27120) // 7h 32m
        XCTAssertEqual(recording.formattedDuration, "7h 32m")
    }

    func test_formattedDuration_exactHours() {
        let recording = makeRecording(duration: 3600) // 1h 0m
        XCTAssertEqual(recording.formattedDuration, "1h 0m")
    }

    func test_formattedDuration_minutesOnly() {
        let recording = makeRecording(duration: 1800) // 30m
        XCTAssertEqual(recording.formattedDuration, "30m")
    }

    func test_formattedDuration_shortDuration() {
        let recording = makeRecording(duration: 600) // 10m
        XCTAssertEqual(recording.formattedDuration, "10m")
    }

    // MARK: - Snoring Minutes

    func test_snoringMinutes_sumsSnoringEvents() {
        let events: [SoundEvent] = [
            SoundEvent(timestamp: 100, duration: 120, type: .snoring, peakDecibels: 55, averageDecibels: 48),
            SoundEvent(timestamp: 500, duration: 180, type: .snoring, peakDecibels: 60, averageDecibels: 50),
            SoundEvent(timestamp: 800, duration: 60, type: .loudSound, peakDecibels: 75, averageDecibels: 65),
            SoundEvent(timestamp: 1200, duration: 300, type: .silence, peakDecibels: 25, averageDecibels: 20),
        ]
        let recording = makeRecording(events: events)
        // 120 + 180 = 300 seconds = 5 minutes
        XCTAssertEqual(recording.snoringMinutes, 5)
    }

    func test_snoringMinutes_noSnoringEvents() {
        let events: [SoundEvent] = [
            SoundEvent(timestamp: 100, duration: 60, type: .loudSound, peakDecibels: 75, averageDecibels: 65),
        ]
        let recording = makeRecording(events: events)
        XCTAssertEqual(recording.snoringMinutes, 0)
    }

    // MARK: - Event Count (excludes silence)

    func test_eventCount_excludesSilence() {
        let events: [SoundEvent] = [
            SoundEvent(timestamp: 100, duration: 10, type: .snoring, peakDecibels: 55, averageDecibels: 48),
            SoundEvent(timestamp: 200, duration: 5, type: .loudSound, peakDecibels: 75, averageDecibels: 65),
            SoundEvent(timestamp: 300, duration: 8, type: .talking, peakDecibels: 50, averageDecibels: 42),
            SoundEvent(timestamp: 500, duration: 600, type: .silence, peakDecibels: 25, averageDecibels: 20),
        ]
        let recording = makeRecording(events: events)
        XCTAssertEqual(recording.eventCount, 3)
    }

    // MARK: - Snore Score Category

    func test_snoreScoreCategory_quiet() {
        XCTAssertEqual(makeRecording(snoreScore: 0).snoreScoreCategory, "Quiet")
        XCTAssertEqual(makeRecording(snoreScore: 15).snoreScoreCategory, "Quiet")
        XCTAssertEqual(makeRecording(snoreScore: 30).snoreScoreCategory, "Quiet")
    }

    func test_snoreScoreCategory_moderate() {
        XCTAssertEqual(makeRecording(snoreScore: 31).snoreScoreCategory, "Moderate")
        XCTAssertEqual(makeRecording(snoreScore: 45).snoreScoreCategory, "Moderate")
        XCTAssertEqual(makeRecording(snoreScore: 60).snoreScoreCategory, "Moderate")
    }

    func test_snoreScoreCategory_loud() {
        XCTAssertEqual(makeRecording(snoreScore: 61).snoreScoreCategory, "Loud")
        XCTAssertEqual(makeRecording(snoreScore: 85).snoreScoreCategory, "Loud")
        XCTAssertEqual(makeRecording(snoreScore: 100).snoreScoreCategory, "Loud")
    }

    // MARK: - SoundEvent Formatted Duration

    func test_eventFormattedDuration_seconds() {
        let event = SoundEvent(timestamp: 0, duration: 12, type: .snoring, peakDecibels: 50, averageDecibels: 40)
        XCTAssertEqual(event.formattedDuration, "12s")
    }

    func test_eventFormattedDuration_exactMinute() {
        let event = SoundEvent(timestamp: 0, duration: 60, type: .snoring, peakDecibels: 50, averageDecibels: 40)
        XCTAssertEqual(event.formattedDuration, "1m")
    }

    func test_eventFormattedDuration_minutesAndSeconds() {
        let event = SoundEvent(timestamp: 0, duration: 90, type: .snoring, peakDecibels: 50, averageDecibels: 40)
        XCTAssertEqual(event.formattedDuration, "1m 30s")
    }

    // MARK: - SoundEventType Properties

    func test_soundEventType_hasDisplayNames() {
        for eventType in SoundEventType.allCases {
            XCTAssertFalse(eventType.displayName.isEmpty)
        }
    }

    func test_soundEventType_hasIcons() {
        XCTAssertEqual(SoundEventType.snoring.icon, "zzz")
        XCTAssertEqual(SoundEventType.loudSound.icon, "speaker.wave.3.fill")
        XCTAssertEqual(SoundEventType.talking.icon, "mouth.fill")
        XCTAssertEqual(SoundEventType.silence.icon, "speaker.slash.fill")
    }

    // MARK: - Empty Recording

    func test_emptyRecording_hasZeroDefaults() {
        let recording = makeRecording()
        XCTAssertEqual(recording.snoringMinutes, 0)
        XCTAssertEqual(recording.eventCount, 0)
        XCTAssertEqual(recording.snoreScore, 0)
        XCTAssertEqual(recording.snoreScoreCategory, "Quiet")
    }

    // MARK: - Formatted Time Range

    func test_formattedTimeRange_hasStartAndEnd() {
        let start = Date(timeIntervalSince1970: 1000000)
        let end = Date(timeIntervalSince1970: 1027200)
        let recording = SleepRecording(
            date: start,
            endDate: end,
            duration: 27200,
            fileURL: URL(fileURLWithPath: "/tmp/test.m4a")
        )
        let range = recording.formattedTimeRange
        XCTAssertTrue(range.contains(" - "), "Time range should contain separator")
    }

    // MARK: - Helpers

    private func makeRecording(
        duration: TimeInterval = 28800,
        events: [SoundEvent] = [],
        snoreScore: Int = 0
    ) -> SleepRecording {
        SleepRecording(
            date: Date(),
            endDate: Date().addingTimeInterval(duration),
            duration: duration,
            fileURL: URL(fileURLWithPath: "/tmp/test.m4a"),
            events: events,
            snoreScore: snoreScore
        )
    }
}
