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

    // MARK: - Ringing State Tests

    @MainActor
    func test_ringingAlarm_initiallyNil() {
        let sut = AlarmService()

        XCTAssertNil(sut.ringingAlarm)
    }

    @MainActor
    func test_isRinging_falseWhenNoRingingAlarm() {
        let sut = AlarmService()

        XCTAssertFalse(sut.isRinging)
    }

    @MainActor
    func test_isRinging_trueWhenRingingAlarmIsSet() {
        let sut = AlarmService()
        let alarm = makeAlarm(label: "Wake Up")

        sut.ringingAlarm = alarm

        XCTAssertTrue(sut.isRinging)
    }

    @MainActor
    func test_ringingAlarm_storesCorrectAlarm() {
        let sut = AlarmService()
        let alarm = makeAlarm(label: "Morning Alarm")

        sut.ringingAlarm = alarm

        XCTAssertEqual(sut.ringingAlarm?.label, "Morning Alarm")
        XCTAssertEqual(sut.ringingAlarm?.id, alarm.id)
    }

    // MARK: - stopAlarmSound Tests

    @MainActor
    func test_stopAlarmSound_clearsRingingAlarm() {
        let sut = AlarmService()
        let alarm = makeAlarm(label: "Test")

        sut.ringingAlarm = alarm
        XCTAssertTrue(sut.isRinging)

        sut.stopAlarmSound()

        XCTAssertNil(sut.ringingAlarm)
        XCTAssertFalse(sut.isRinging)
    }

    @MainActor
    func test_stopAlarmSound_whenNotRinging_doesNotCrash() {
        let sut = AlarmService()

        XCTAssertNil(sut.ringingAlarm)

        sut.stopAlarmSound()

        XCTAssertNil(sut.ringingAlarm)
        XCTAssertFalse(sut.isRinging)
    }

    // MARK: - remainingNotificationSlots Tests

    @MainActor
    func test_remainingNotificationSlots_noAlarms_returns64() {
        let sut = AlarmService()

        XCTAssertEqual(sut.remainingNotificationSlots, 64)
    }

    @MainActor
    func test_remainingNotificationSlots_oneEnabledOneTimeAlarm_returns61() {
        let sut = AlarmService()
        // One-time alarm uses 3 slots (one chain of 3 notifications)
        let alarm = makeAlarm(label: "One-time")
        sut.addAlarm(alarm)

        XCTAssertEqual(sut.remainingNotificationSlots, 61)
    }

    @MainActor
    func test_remainingNotificationSlots_oneDisabledAlarm_returns64() {
        let sut = AlarmService()
        var alarm = makeAlarm(label: "Disabled")
        alarm = Alarm(
            id: alarm.id,
            time: alarm.time,
            repeatDays: alarm.repeatDays,
            soundId: alarm.soundId,
            volumeRampMinutes: alarm.volumeRampMinutes,
            snoozeMinutes: alarm.snoozeMinutes,
            isEnabled: false,
            label: alarm.label
        )
        sut.addAlarm(alarm)

        // Disabled alarms should not use any notification slots
        XCTAssertEqual(sut.remainingNotificationSlots, 64)
    }

    @MainActor
    func test_remainingNotificationSlots_repeatingAlarm_usesPerDaySlots() {
        let sut = AlarmService()
        // Repeating alarm with 3 days: uses 3 days * 3 chains = 9 slots
        let alarm = Alarm(
            time: makeDate(hour: 7, minute: 0),
            repeatDays: [.monday, .wednesday, .friday],
            soundId: "morning_birds",
            volumeRampMinutes: 5,
            snoozeMinutes: 10,
            isEnabled: true,
            label: "Weekday Alarm"
        )
        sut.addAlarm(alarm)

        XCTAssertEqual(sut.remainingNotificationSlots, 55) // 64 - 9
    }

    @MainActor
    func test_remainingNotificationSlots_everyDayAlarm_uses21Slots() {
        let sut = AlarmService()
        // Every day: 7 days * 3 chains = 21 slots
        let alarm = Alarm(
            time: makeDate(hour: 7, minute: 0),
            repeatDays: Set(Weekday.allCases),
            soundId: "morning_birds",
            volumeRampMinutes: 5,
            snoozeMinutes: 10,
            isEnabled: true,
            label: "Every Day"
        )
        sut.addAlarm(alarm)

        XCTAssertEqual(sut.remainingNotificationSlots, 43) // 64 - 21
    }

    @MainActor
    func test_remainingNotificationSlots_multipleAlarms_accumulatesCorrectly() {
        let sut = AlarmService()

        // Alarm 1: one-time = 3 slots
        let alarm1 = makeAlarm(time: makeDate(hour: 6, minute: 0), label: "One-time")
        sut.addAlarm(alarm1)

        // Alarm 2: repeating on 2 days = 6 slots
        let alarm2 = Alarm(
            time: makeDate(hour: 8, minute: 0),
            repeatDays: [.monday, .friday],
            soundId: "morning_birds",
            volumeRampMinutes: 5,
            snoozeMinutes: 10,
            isEnabled: true,
            label: "Repeating"
        )
        sut.addAlarm(alarm2)

        // Total used: 3 + 6 = 9
        XCTAssertEqual(sut.remainingNotificationSlots, 55) // 64 - 9
    }

    @MainActor
    func test_remainingNotificationSlots_neverGoesNegative() {
        let sut = AlarmService()

        // Add many repeating alarms to potentially exceed 64 slots
        for i in 0..<5 {
            let alarm = Alarm(
                time: makeDate(hour: 6 + i, minute: 0),
                repeatDays: Set(Weekday.allCases), // 7 * 3 = 21 slots each
                soundId: "morning_birds",
                volumeRampMinutes: 5,
                snoozeMinutes: 10,
                isEnabled: true,
                label: "Alarm \(i)"
            )
            sut.addAlarm(alarm)
        }

        // 5 * 21 = 105 used, but result should be max(0, 64 - 105) = 0
        XCTAssertEqual(sut.remainingNotificationSlots, 0)
    }

    @MainActor
    func test_remainingNotificationSlots_mixedEnabledDisabled() {
        let sut = AlarmService()

        // Enabled one-time alarm: 3 slots
        let enabledAlarm = makeAlarm(time: makeDate(hour: 6, minute: 0), label: "Enabled")
        sut.addAlarm(enabledAlarm)

        // Disabled repeating alarm: 0 slots (disabled)
        let disabledAlarm = Alarm(
            time: makeDate(hour: 8, minute: 0),
            repeatDays: Set(Weekday.allCases),
            soundId: "morning_birds",
            volumeRampMinutes: 5,
            snoozeMinutes: 10,
            isEnabled: true,
            label: "Will Disable"
        )
        sut.addAlarm(disabledAlarm)
        sut.toggleAlarm(sut.alarms.first(where: { $0.label == "Will Disable" })!)

        // Only 3 slots from enabled alarm
        XCTAssertEqual(sut.remainingNotificationSlots, 61)
    }

    @MainActor
    func test_remainingNotificationSlots_weekendAlarm_uses6Slots() {
        let sut = AlarmService()

        let alarm = Alarm(
            time: makeDate(hour: 9, minute: 0),
            repeatDays: [.saturday, .sunday],
            soundId: "morning_birds",
            volumeRampMinutes: 5,
            snoozeMinutes: 10,
            isEnabled: true,
            label: "Weekend"
        )
        sut.addAlarm(alarm)

        // 2 days * 3 chains = 6 slots
        XCTAssertEqual(sut.remainingNotificationSlots, 58) // 64 - 6
    }

    // MARK: - disableOneTimeAlarmIfNeeded Tests

    @MainActor
    func test_disableOneTimeAlarmIfNeeded_disablesOneTimeAlarm() {
        let sut = AlarmService()
        let alarm = makeAlarm(label: "One-time Alarm")
        sut.addAlarm(alarm)

        XCTAssertTrue(sut.alarms[0].isEnabled)
        XCTAssertTrue(sut.alarms[0].repeatDays.isEmpty, "Should be a one-time alarm")

        // Simulate the alarm firing by posting the notification
        NotificationCenter.default.post(
            name: AppDelegate.alarmFiredNotification,
            object: nil,
            userInfo: [AppDelegate.alarmIdKey: alarm.id.uuidString]
        )

        // Give the async Task time to process
        let expectation = expectation(description: "One-time alarm disabled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)

        XCTAssertFalse(sut.alarms[0].isEnabled, "One-time alarm should be auto-disabled after firing")
    }

    @MainActor
    func test_disableOneTimeAlarmIfNeeded_doesNotDisableRepeatingAlarm() {
        let sut = AlarmService()
        let alarm = Alarm(
            time: makeDate(hour: 7, minute: 0),
            repeatDays: [.monday, .wednesday, .friday],
            soundId: "morning_birds",
            volumeRampMinutes: 5,
            snoozeMinutes: 10,
            isEnabled: true,
            label: "Repeating Alarm"
        )
        sut.addAlarm(alarm)

        XCTAssertTrue(sut.alarms[0].isEnabled)

        // Simulate alarm firing
        NotificationCenter.default.post(
            name: AppDelegate.alarmFiredNotification,
            object: nil,
            userInfo: [AppDelegate.alarmIdKey: alarm.id.uuidString]
        )

        let expectation = expectation(description: "Repeating alarm stays enabled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)

        XCTAssertTrue(sut.alarms[0].isEnabled, "Repeating alarm should remain enabled after firing")
    }

    // MARK: - Notification Event Handling Tests

    @MainActor
    func test_alarmFired_setsRingingAlarm() {
        let sut = AlarmService()
        let alarm = makeAlarm(label: "Ringing Test")
        sut.addAlarm(alarm)

        NotificationCenter.default.post(
            name: AppDelegate.alarmFiredNotification,
            object: nil,
            userInfo: [AppDelegate.alarmIdKey: alarm.id.uuidString]
        )

        let expectation = expectation(description: "Ringing alarm set")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)

        XCTAssertNotNil(sut.ringingAlarm)
        XCTAssertEqual(sut.ringingAlarm?.id, alarm.id)
        XCTAssertTrue(sut.isRinging)
    }

    @MainActor
    func test_alarmFired_withUnknownId_doesNotSetRinging() {
        let sut = AlarmService()
        let alarm = makeAlarm(label: "Known Alarm")
        sut.addAlarm(alarm)

        let unknownId = UUID().uuidString
        NotificationCenter.default.post(
            name: AppDelegate.alarmFiredNotification,
            object: nil,
            userInfo: [AppDelegate.alarmIdKey: unknownId]
        )

        let expectation = expectation(description: "No ringing for unknown alarm")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)

        XCTAssertNil(sut.ringingAlarm)
        XCTAssertFalse(sut.isRinging)
    }

    @MainActor
    func test_alarmAction_stop_clearsRingingState() {
        let sut = AlarmService()
        let alarm = makeAlarm(label: "Stop Test")
        sut.addAlarm(alarm)

        // First set ringing state
        sut.ringingAlarm = alarm

        // Then post stop action
        NotificationCenter.default.post(
            name: AppDelegate.alarmActionNotification,
            object: nil,
            userInfo: [
                AppDelegate.alarmIdKey: alarm.id.uuidString,
                AppDelegate.actionTypeKey: AppDelegate.AlarmActionType.stop.rawValue
            ]
        )

        let expectation = expectation(description: "Ringing cleared by stop")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)

        XCTAssertNil(sut.ringingAlarm)
        XCTAssertFalse(sut.isRinging)
    }

    @MainActor
    func test_alarmAction_snooze_clearsRingingState() {
        let sut = AlarmService()
        let alarm = makeAlarm(label: "Snooze Test")
        sut.addAlarm(alarm)

        sut.ringingAlarm = alarm

        NotificationCenter.default.post(
            name: AppDelegate.alarmActionNotification,
            object: nil,
            userInfo: [
                AppDelegate.alarmIdKey: alarm.id.uuidString,
                AppDelegate.actionTypeKey: AppDelegate.AlarmActionType.snooze.rawValue
            ]
        )

        let expectation = expectation(description: "Ringing cleared by snooze")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)

        // Snooze calls stopAlarmSound which clears ringing
        XCTAssertNil(sut.ringingAlarm)
    }

    @MainActor
    func test_alarmAction_fired_setsRingingAlarm() {
        let sut = AlarmService()
        let alarm = makeAlarm(label: "Fired Action")
        sut.addAlarm(alarm)

        NotificationCenter.default.post(
            name: AppDelegate.alarmActionNotification,
            object: nil,
            userInfo: [
                AppDelegate.alarmIdKey: alarm.id.uuidString,
                AppDelegate.actionTypeKey: AppDelegate.AlarmActionType.fired.rawValue
            ]
        )

        let expectation = expectation(description: "Ringing set by fired action")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)

        XCTAssertNotNil(sut.ringingAlarm)
        XCTAssertEqual(sut.ringingAlarm?.id, alarm.id)
    }

    // MARK: - Slot Budget After Toggle Tests

    @MainActor
    func test_remainingNotificationSlots_updatesAfterToggle() {
        let sut = AlarmService()
        let alarm = makeAlarm(time: makeDate(hour: 7, minute: 0), label: "Toggle Test")
        sut.addAlarm(alarm)

        XCTAssertEqual(sut.remainingNotificationSlots, 61) // 64 - 3

        sut.toggleAlarm(sut.alarms[0])
        // After disabling, should free up slots
        XCTAssertEqual(sut.remainingNotificationSlots, 64)

        sut.toggleAlarm(sut.alarms[0])
        // After re-enabling, slots used again
        XCTAssertEqual(sut.remainingNotificationSlots, 61)
    }

    @MainActor
    func test_remainingNotificationSlots_updatesAfterDelete() {
        let sut = AlarmService()
        let alarm = makeAlarm(time: makeDate(hour: 7, minute: 0), label: "Delete Test")
        sut.addAlarm(alarm)

        XCTAssertEqual(sut.remainingNotificationSlots, 61)

        sut.deleteAlarm(sut.alarms[0])

        XCTAssertEqual(sut.remainingNotificationSlots, 64)
    }

    @MainActor
    func test_remainingNotificationSlots_singleDayRepeat_uses3Slots() {
        let sut = AlarmService()

        let alarm = Alarm(
            time: makeDate(hour: 7, minute: 0),
            repeatDays: [.monday],
            soundId: "morning_birds",
            volumeRampMinutes: 5,
            snoozeMinutes: 10,
            isEnabled: true,
            label: "Monday Only"
        )
        sut.addAlarm(alarm)

        // 1 day * 3 chains = 3 slots
        XCTAssertEqual(sut.remainingNotificationSlots, 61)
    }
}
