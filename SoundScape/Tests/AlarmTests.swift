import XCTest
@testable import SoundScape

final class AlarmTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeAlarm(repeatDays: Set<Weekday> = []) -> Alarm {
        return Alarm(
            time: Date(),
            repeatDays: repeatDays,
            soundId: "morning_birds",
            volumeRampMinutes: 5,
            snoozeMinutes: 10,
            isEnabled: true,
            label: "Test"
        )
    }

    // MARK: - repeatDescription Tests

    func test_repeatDescription_emptyDays_returnsOnce() {
        let alarm = makeAlarm(repeatDays: [])

        XCTAssertEqual(alarm.repeatDescription, "Once")
    }

    func test_repeatDescription_allDays_returnsEveryDay() {
        let alarm = makeAlarm(repeatDays: Set(Weekday.allCases))

        XCTAssertEqual(alarm.repeatDescription, "Every day")
    }

    func test_repeatDescription_weekend_returnsWeekends() {
        let alarm = makeAlarm(repeatDays: [.saturday, .sunday])

        XCTAssertEqual(alarm.repeatDescription, "Weekends")
    }

    func test_repeatDescription_weekdays_returnsWeekdays() {
        let alarm = makeAlarm(repeatDays: [.monday, .tuesday, .wednesday, .thursday, .friday])

        XCTAssertEqual(alarm.repeatDescription, "Weekdays")
    }

    func test_repeatDescription_customDays_returnsAbbreviatedNames() {
        let alarm = makeAlarm(repeatDays: [.monday, .wednesday, .friday])

        let description = alarm.repeatDescription
        XCTAssertTrue(description.contains("M"), "Should contain Monday abbreviation")
        XCTAssertTrue(description.contains("W"), "Should contain Wednesday abbreviation")
        XCTAssertTrue(description.contains("F"), "Should contain Friday abbreviation")
    }

    func test_repeatDescription_singleDay_returnsDayAbbreviation() {
        let alarm = makeAlarm(repeatDays: [.tuesday])

        XCTAssertEqual(alarm.repeatDescription, "T")
    }

    func test_repeatDescription_twoDays_returnsCorrectFormat() {
        let alarm = makeAlarm(repeatDays: [.monday, .friday])

        let description = alarm.repeatDescription
        XCTAssertTrue(description.contains("M"))
        XCTAssertTrue(description.contains("F"))
    }

    // MARK: - Weekday Tests

    func test_weekday_shortNames() {
        XCTAssertEqual(Weekday.sunday.shortName, "S")
        XCTAssertEqual(Weekday.monday.shortName, "M")
        XCTAssertEqual(Weekday.tuesday.shortName, "T")
        XCTAssertEqual(Weekday.wednesday.shortName, "W")
        XCTAssertEqual(Weekday.thursday.shortName, "T")
        XCTAssertEqual(Weekday.friday.shortName, "F")
        XCTAssertEqual(Weekday.saturday.shortName, "S")
    }

    func test_weekday_fullNames() {
        XCTAssertEqual(Weekday.sunday.fullName, "Sunday")
        XCTAssertEqual(Weekday.monday.fullName, "Monday")
        XCTAssertEqual(Weekday.tuesday.fullName, "Tuesday")
        XCTAssertEqual(Weekday.wednesday.fullName, "Wednesday")
        XCTAssertEqual(Weekday.thursday.fullName, "Thursday")
        XCTAssertEqual(Weekday.friday.fullName, "Friday")
        XCTAssertEqual(Weekday.saturday.fullName, "Saturday")
    }

    func test_weekday_rawValues() {
        XCTAssertEqual(Weekday.sunday.rawValue, 1)
        XCTAssertEqual(Weekday.monday.rawValue, 2)
        XCTAssertEqual(Weekday.tuesday.rawValue, 3)
        XCTAssertEqual(Weekday.wednesday.rawValue, 4)
        XCTAssertEqual(Weekday.thursday.rawValue, 5)
        XCTAssertEqual(Weekday.friday.rawValue, 6)
        XCTAssertEqual(Weekday.saturday.rawValue, 7)
    }

    func test_weekday_displayOrder() {
        XCTAssertEqual(Weekday.monday.displayOrder, 0)
        XCTAssertEqual(Weekday.tuesday.displayOrder, 1)
        XCTAssertEqual(Weekday.wednesday.displayOrder, 2)
        XCTAssertEqual(Weekday.thursday.displayOrder, 3)
        XCTAssertEqual(Weekday.friday.displayOrder, 4)
        XCTAssertEqual(Weekday.saturday.displayOrder, 5)
        XCTAssertEqual(Weekday.sunday.displayOrder, 6)
    }

    func test_weekday_orderedForDisplay() {
        let ordered = Weekday.orderedForDisplay

        XCTAssertEqual(ordered.count, 7)
        XCTAssertEqual(ordered[0], .monday)
        XCTAssertEqual(ordered[1], .tuesday)
        XCTAssertEqual(ordered[2], .wednesday)
        XCTAssertEqual(ordered[3], .thursday)
        XCTAssertEqual(ordered[4], .friday)
        XCTAssertEqual(ordered[5], .saturday)
        XCTAssertEqual(ordered[6], .sunday)
    }

    func test_weekday_comparable() {
        XCTAssertTrue(Weekday.sunday < Weekday.monday)
        XCTAssertTrue(Weekday.monday < Weekday.saturday)
        XCTAssertFalse(Weekday.friday < Weekday.monday)
    }

    // MARK: - Alarm Codable Tests

    func test_alarm_encodeDecode() throws {
        let original = makeAlarm(repeatDays: [.monday, .wednesday])

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Alarm.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.label, original.label)
        XCTAssertEqual(decoded.repeatDays, original.repeatDays)
        XCTAssertEqual(decoded.soundId, original.soundId)
        XCTAssertEqual(decoded.isEnabled, original.isEnabled)
    }

    // MARK: - Alarm Default Values

    func test_alarm_defaultValues() {
        let alarm = Alarm()

        XCTAssertEqual(alarm.soundId, "morning_birds")
        XCTAssertEqual(alarm.volumeRampMinutes, 5)
        XCTAssertEqual(alarm.snoozeMinutes, 10)
        XCTAssertTrue(alarm.isEnabled)
        XCTAssertEqual(alarm.label, "Alarm")
        XCTAssertTrue(alarm.repeatDays.isEmpty)
    }

    // MARK: - timeString Tests

    func test_alarm_timeString_formatsCorrectly() {
        var components = DateComponents()
        components.hour = 7
        components.minute = 30
        let time = Calendar.current.date(from: components)!

        let alarm = Alarm(time: time)

        XCTAssertFalse(alarm.timeString.isEmpty)
    }
}
