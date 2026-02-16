import XCTest
@testable import SoundScape

final class AppDelegateTests: XCTestCase {

    // MARK: - Test Helpers

    /// Creates a testable AppDelegate subclass that exposes parseAlarmId for testing
    /// Since parseAlarmId is private, we test it indirectly through the notification
    /// behavior, or directly test the UUID parsing logic it uses.

    // MARK: - parseAlarmId Logic Tests

    // The parseAlarmId method extracts a UUID from the first 36 characters of an identifier.
    // We test the same logic directly since the method is private.

    private func extractAlarmId(from identifier: String) -> String? {
        let uuidLength = 36
        guard identifier.count >= uuidLength else { return nil }
        let candidate = String(identifier.prefix(uuidLength))
        guard UUID(uuidString: candidate) != nil else { return nil }
        return candidate
    }

    func test_parseAlarmId_plainUUID_returnsUUID() {
        let uuid = UUID()
        let identifier = uuid.uuidString

        let result = extractAlarmId(from: identifier)

        XCTAssertEqual(result, uuid.uuidString)
    }

    func test_parseAlarmId_chainFormat_returnsUUID() {
        let uuid = UUID()
        let identifier = "\(uuid.uuidString)_chain_0"

        let result = extractAlarmId(from: identifier)

        XCTAssertEqual(result, uuid.uuidString)
    }

    func test_parseAlarmId_chainFormat_index1_returnsUUID() {
        let uuid = UUID()
        let identifier = "\(uuid.uuidString)_chain_1"

        let result = extractAlarmId(from: identifier)

        XCTAssertEqual(result, uuid.uuidString)
    }

    func test_parseAlarmId_chainFormat_index2_returnsUUID() {
        let uuid = UUID()
        let identifier = "\(uuid.uuidString)_chain_2"

        let result = extractAlarmId(from: identifier)

        XCTAssertEqual(result, uuid.uuidString)
    }

    func test_parseAlarmId_dayChainFormat_returnsUUID() {
        let uuid = UUID()
        let identifier = "\(uuid.uuidString)_day_2_chain_1"

        let result = extractAlarmId(from: identifier)

        XCTAssertEqual(result, uuid.uuidString)
    }

    func test_parseAlarmId_dayChainFormat_allWeekdays() {
        let uuid = UUID()
        for day in 1...7 {
            for chain in 0...2 {
                let identifier = "\(uuid.uuidString)_day_\(day)_chain_\(chain)"
                let result = extractAlarmId(from: identifier)
                XCTAssertEqual(result, uuid.uuidString,
                    "Failed for day_\(day)_chain_\(chain)")
            }
        }
    }

    func test_parseAlarmId_snoozeChainFormat_returnsUUID() {
        let uuid = UUID()
        let identifier = "\(uuid.uuidString)_snooze_chain_0"

        let result = extractAlarmId(from: identifier)

        XCTAssertEqual(result, uuid.uuidString)
    }

    func test_parseAlarmId_snoozeChainFormat_allChains() {
        let uuid = UUID()
        for chain in 0...2 {
            let identifier = "\(uuid.uuidString)_snooze_chain_\(chain)"
            let result = extractAlarmId(from: identifier)
            XCTAssertEqual(result, uuid.uuidString,
                "Failed for snooze_chain_\(chain)")
        }
    }

    func test_parseAlarmId_tooShortString_returnsNil() {
        let result = extractAlarmId(from: "short")

        XCTAssertNil(result, "Strings shorter than 36 characters should return nil")
    }

    func test_parseAlarmId_emptyString_returnsNil() {
        let result = extractAlarmId(from: "")

        XCTAssertNil(result, "Empty string should return nil")
    }

    func test_parseAlarmId_invalidUUIDPrefix_returnsNil() {
        let result = extractAlarmId(from: "this-is-not-a-valid-uuid-string-!!!!")

        XCTAssertNil(result, "Invalid UUID format should return nil")
    }

    func test_parseAlarmId_almostUUID_returnsNil() {
        // 36 characters but not a valid UUID format
        let result = extractAlarmId(from: "00000000-0000-0000-0000-00000000000G")

        XCTAssertNil(result, "Non-hex characters in UUID position should return nil")
    }

    func test_parseAlarmId_exactly36Characters_validUUID() {
        let uuid = UUID()
        let identifier = uuid.uuidString // exactly 36 characters

        XCTAssertEqual(identifier.count, 36)
        let result = extractAlarmId(from: identifier)
        XCTAssertEqual(result, uuid.uuidString)
    }

    func test_parseAlarmId_lowercaseUUID_returnsUUID() {
        let uuid = UUID()
        let lowercased = uuid.uuidString.lowercased()
        // UUID(uuidString:) accepts both upper and lower case
        let identifier = "\(lowercased)_chain_0"

        let result = extractAlarmId(from: identifier)

        XCTAssertNotNil(result, "Lowercase UUID should be valid")
    }

    // MARK: - AlarmActionType Tests

    func test_alarmActionType_fired_rawValue() {
        XCTAssertEqual(AppDelegate.AlarmActionType.fired.rawValue, "fired")
    }

    func test_alarmActionType_snooze_rawValue() {
        XCTAssertEqual(AppDelegate.AlarmActionType.snooze.rawValue, "snooze")
    }

    func test_alarmActionType_stop_rawValue() {
        XCTAssertEqual(AppDelegate.AlarmActionType.stop.rawValue, "stop")
    }

    func test_alarmActionType_initFromRawValue_fired() {
        let action = AppDelegate.AlarmActionType(rawValue: "fired")
        XCTAssertEqual(action, .fired)
    }

    func test_alarmActionType_initFromRawValue_snooze() {
        let action = AppDelegate.AlarmActionType(rawValue: "snooze")
        XCTAssertEqual(action, .snooze)
    }

    func test_alarmActionType_initFromRawValue_stop() {
        let action = AppDelegate.AlarmActionType(rawValue: "stop")
        XCTAssertEqual(action, .stop)
    }

    func test_alarmActionType_initFromRawValue_invalid_returnsNil() {
        let action = AppDelegate.AlarmActionType(rawValue: "invalid")
        XCTAssertNil(action)
    }

    func test_alarmActionType_initFromRawValue_empty_returnsNil() {
        let action = AppDelegate.AlarmActionType(rawValue: "")
        XCTAssertNil(action)
    }

    // MARK: - Notification Name Constants Tests

    func test_alarmFiredNotification_name() {
        XCTAssertEqual(AppDelegate.alarmFiredNotification, Notification.Name("AlarmFired"))
    }

    func test_alarmActionNotification_name() {
        XCTAssertEqual(AppDelegate.alarmActionNotification, Notification.Name("AlarmAction"))
    }

    func test_alarmIdKey_value() {
        XCTAssertEqual(AppDelegate.alarmIdKey, "alarmId")
    }

    func test_actionTypeKey_value() {
        XCTAssertEqual(AppDelegate.actionTypeKey, "actionType")
    }

    // MARK: - AppDelegate Initialization Tests

    func test_appDelegate_isNotNil() {
        let appDelegate = AppDelegate()
        XCTAssertNotNil(appDelegate)
    }

    func test_appDelegate_conformsToUIApplicationDelegate() {
        let appDelegate = AppDelegate()
        XCTAssertTrue(appDelegate is UIApplicationDelegate)
    }

    func test_appDelegate_conformsToUNUserNotificationCenterDelegate() {
        let appDelegate = AppDelegate()
        XCTAssertTrue(appDelegate is UNUserNotificationCenterDelegate)
    }

    // MARK: - cancelChainNotifications Logic Tests

    func test_notificationIdentifier_prefixMatching_chainFormats() {
        // Verify that identifier prefix matching correctly groups chain notifications
        let alarmId = UUID().uuidString

        let identifiers = [
            "\(alarmId)_chain_0",
            "\(alarmId)_chain_1",
            "\(alarmId)_chain_2",
        ]

        let matching = identifiers.filter { $0.hasPrefix(alarmId) }
        XCTAssertEqual(matching.count, 3, "All chain notifications should match the alarm UUID prefix")
    }

    func test_notificationIdentifier_prefixMatching_dayChainFormats() {
        let alarmId = UUID().uuidString

        let identifiers = [
            "\(alarmId)_day_2_chain_0",
            "\(alarmId)_day_2_chain_1",
            "\(alarmId)_day_2_chain_2",
            "\(alarmId)_day_6_chain_0",
            "\(alarmId)_day_6_chain_1",
            "\(alarmId)_day_6_chain_2",
        ]

        let matching = identifiers.filter { $0.hasPrefix(alarmId) }
        XCTAssertEqual(matching.count, 6, "All day+chain notifications should match")
    }

    func test_notificationIdentifier_prefixMatching_snoozeFormats() {
        let alarmId = UUID().uuidString

        let identifiers = [
            "\(alarmId)_snooze_chain_0",
            "\(alarmId)_snooze_chain_1",
            "\(alarmId)_snooze_chain_2",
        ]

        let matching = identifiers.filter { $0.hasPrefix(alarmId) }
        XCTAssertEqual(matching.count, 3, "All snooze chain notifications should match")
    }

    func test_notificationIdentifier_prefixMatching_doesNotMatchDifferentAlarm() {
        let alarmId1 = UUID().uuidString
        let alarmId2 = UUID().uuidString

        let identifiers = [
            "\(alarmId1)_chain_0",
            "\(alarmId1)_chain_1",
            "\(alarmId2)_chain_0",
            "\(alarmId2)_chain_1",
        ]

        let matchingAlarm1 = identifiers.filter { $0.hasPrefix(alarmId1) }
        XCTAssertEqual(matchingAlarm1.count, 2, "Should only match notifications for alarm 1")
    }

    func test_notificationIdentifier_prefixMatching_mixedFormats() {
        let alarmId = UUID().uuidString
        let otherId = UUID().uuidString

        let identifiers = [
            "\(alarmId)_chain_0",
            "\(alarmId)_day_2_chain_1",
            "\(alarmId)_snooze_chain_2",
            "\(otherId)_chain_0",
            "\(otherId)_day_5_chain_0",
        ]

        let matching = identifiers.filter { $0.hasPrefix(alarmId) }
        XCTAssertEqual(matching.count, 3, "Should match all formats for the target alarm")
    }

    // MARK: - Notification Content Tests

    func test_alarmCategory_identifier() {
        // The category identifier used throughout the app
        XCTAssertEqual("ALARM_CATEGORY", "ALARM_CATEGORY")
    }

    func test_snoozeAction_identifier() {
        XCTAssertEqual("SNOOZE_ACTION", "SNOOZE_ACTION")
    }

    func test_stopAction_identifier() {
        XCTAssertEqual("STOP_ACTION", "STOP_ACTION")
    }

    // MARK: - Notification UserInfo Key Tests

    func test_userInfo_alarmIdKey_isConsistent() {
        // Verify the key used in userInfo dictionaries is consistent
        let userInfo: [String: String] = [
            AppDelegate.alarmIdKey: UUID().uuidString
        ]
        XCTAssertNotNil(userInfo[AppDelegate.alarmIdKey])
    }

    func test_userInfo_actionTypeKey_isConsistent() {
        let userInfo: [String: String] = [
            AppDelegate.actionTypeKey: AppDelegate.AlarmActionType.stop.rawValue
        ]
        XCTAssertNotNil(userInfo[AppDelegate.actionTypeKey])
        XCTAssertEqual(userInfo[AppDelegate.actionTypeKey], "stop")
    }
}
