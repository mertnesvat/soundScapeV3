import XCTest
@testable import SoundScape

final class AlarmServiceTests: XCTestCase {

    // MARK: - Setup and Teardown

    private var testFileURL: URL!

    override func setUp() {
        super.setUp()
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        testFileURL = documentsPath.appendingPathComponent("alarms.json")
        try? FileManager.default.removeItem(at: testFileURL)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: testFileURL)
        testFileURL = nil
        super.tearDown()
    }

    // MARK: - Test Helpers

    private func makeAlarm(
        time: Date = Date(),
        repeatDays: Set<Weekday> = [],
        label: String = "Test Alarm"
    ) -> Alarm {
        return Alarm(
            time: time,
            repeatDays: repeatDays,
            soundId: "morning_birds",
            volumeRampMinutes: 5,
            snoozeMinutes: 10,
            isEnabled: true,
            label: label
        )
    }

    private func makeDate(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 15
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }

    // MARK: - Initial State Tests

    @MainActor
    func test_init_startsWithEmptyAlarms() {
        let sut = AlarmService()

        XCTAssertTrue(sut.alarms.isEmpty)
    }

    // MARK: - addAlarm Tests

    @MainActor
    func test_addAlarm_addsAlarmToList() {
        let sut = AlarmService()
        let alarm = makeAlarm()

        sut.addAlarm(alarm)

        XCTAssertEqual(sut.alarms.count, 1)
        XCTAssertEqual(sut.alarms[0].label, "Test Alarm")
    }

    @MainActor
    func test_addAlarm_sortsByTime() {
        let sut = AlarmService()

        let laterAlarm = makeAlarm(time: makeDate(hour: 10, minute: 0), label: "Later")
        let earlierAlarm = makeAlarm(time: makeDate(hour: 6, minute: 0), label: "Earlier")

        sut.addAlarm(laterAlarm)
        sut.addAlarm(earlierAlarm)

        XCTAssertEqual(sut.alarms[0].label, "Earlier")
        XCTAssertEqual(sut.alarms[1].label, "Later")
    }

    // MARK: - deleteAlarm Tests

    @MainActor
    func test_deleteAlarm_removesCorrectAlarmById() {
        let sut = AlarmService()
        let alarm1 = makeAlarm(label: "Alarm 1")
        let alarm2 = makeAlarm(label: "Alarm 2")

        sut.addAlarm(alarm1)
        sut.addAlarm(alarm2)

        sut.deleteAlarm(alarm1)

        XCTAssertEqual(sut.alarms.count, 1)
        XCTAssertEqual(sut.alarms[0].label, "Alarm 2")
    }

    @MainActor
    func test_deleteAlarm_withNonexistentAlarm_doesNotCrash() {
        let sut = AlarmService()
        let alarm = makeAlarm(label: "Real Alarm")
        sut.addAlarm(alarm)

        let fakeAlarm = makeAlarm(label: "Fake Alarm")

        sut.deleteAlarm(fakeAlarm)

        XCTAssertEqual(sut.alarms.count, 1)
    }

    // MARK: - toggleAlarm Tests

    @MainActor
    func test_toggleAlarm_togglesIsEnabledFlag() {
        let sut = AlarmService()
        var alarm = makeAlarm()
        alarm = Alarm(
            id: alarm.id,
            time: alarm.time,
            repeatDays: alarm.repeatDays,
            soundId: alarm.soundId,
            volumeRampMinutes: alarm.volumeRampMinutes,
            snoozeMinutes: alarm.snoozeMinutes,
            isEnabled: true,
            label: alarm.label
        )

        sut.addAlarm(alarm)
        XCTAssertTrue(sut.alarms[0].isEnabled)

        sut.toggleAlarm(sut.alarms[0])

        XCTAssertFalse(sut.alarms[0].isEnabled)
    }

    @MainActor
    func test_toggleAlarm_twiceReturnToOriginalState() {
        let sut = AlarmService()
        let alarm = makeAlarm()

        sut.addAlarm(alarm)
        let originalState = sut.alarms[0].isEnabled

        sut.toggleAlarm(sut.alarms[0])
        sut.toggleAlarm(sut.alarms[0])

        XCTAssertEqual(sut.alarms[0].isEnabled, originalState)
    }

    // MARK: - updateAlarm Tests

    @MainActor
    func test_updateAlarm_updatesAlarm() {
        let sut = AlarmService()
        let alarm = makeAlarm(time: makeDate(hour: 6, minute: 0), label: "Original")

        sut.addAlarm(alarm)

        var updatedAlarm = sut.alarms[0]
        updatedAlarm = Alarm(
            id: updatedAlarm.id,
            time: makeDate(hour: 7, minute: 30),
            repeatDays: updatedAlarm.repeatDays,
            soundId: updatedAlarm.soundId,
            volumeRampMinutes: updatedAlarm.volumeRampMinutes,
            snoozeMinutes: updatedAlarm.snoozeMinutes,
            isEnabled: updatedAlarm.isEnabled,
            label: "Updated"
        )

        sut.updateAlarm(updatedAlarm)

        XCTAssertEqual(sut.alarms[0].label, "Updated")
    }

    @MainActor
    func test_updateAlarm_resortsAfterUpdate() {
        let sut = AlarmService()

        let alarm1 = makeAlarm(time: makeDate(hour: 6, minute: 0), label: "First")
        let alarm2 = makeAlarm(time: makeDate(hour: 8, minute: 0), label: "Second")

        sut.addAlarm(alarm1)
        sut.addAlarm(alarm2)

        var updatedAlarm = sut.alarms[0]
        updatedAlarm = Alarm(
            id: updatedAlarm.id,
            time: makeDate(hour: 10, minute: 0),
            repeatDays: updatedAlarm.repeatDays,
            soundId: updatedAlarm.soundId,
            volumeRampMinutes: updatedAlarm.volumeRampMinutes,
            snoozeMinutes: updatedAlarm.snoozeMinutes,
            isEnabled: updatedAlarm.isEnabled,
            label: "First-Updated"
        )

        sut.updateAlarm(updatedAlarm)

        XCTAssertEqual(sut.alarms[0].label, "Second")
        XCTAssertEqual(sut.alarms[1].label, "First-Updated")
    }

    // MARK: - Sorting Tests

    @MainActor
    func test_alarms_alwaysSortedByTime() {
        let sut = AlarmService()

        sut.addAlarm(makeAlarm(time: makeDate(hour: 12, minute: 0), label: "Noon"))
        sut.addAlarm(makeAlarm(time: makeDate(hour: 6, minute: 0), label: "Morning"))
        sut.addAlarm(makeAlarm(time: makeDate(hour: 22, minute: 0), label: "Night"))
        sut.addAlarm(makeAlarm(time: makeDate(hour: 8, minute: 30), label: "Mid-morning"))

        XCTAssertEqual(sut.alarms[0].label, "Morning")
        XCTAssertEqual(sut.alarms[1].label, "Mid-morning")
        XCTAssertEqual(sut.alarms[2].label, "Noon")
        XCTAssertEqual(sut.alarms[3].label, "Night")
    }

    // MARK: - Edge Cases

    @MainActor
    func test_addAlarm_multipleAlarmsAtSameTime_doesNotCrash() {
        let sut = AlarmService()
        let time = makeDate(hour: 7, minute: 0)

        sut.addAlarm(makeAlarm(time: time, label: "Alarm 1"))
        sut.addAlarm(makeAlarm(time: time, label: "Alarm 2"))
        sut.addAlarm(makeAlarm(time: time, label: "Alarm 3"))

        XCTAssertEqual(sut.alarms.count, 3)
    }
}
