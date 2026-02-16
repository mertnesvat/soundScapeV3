import Foundation
import UserNotifications
import AVFoundation
import SwiftUI

@Observable
@MainActor
final class AlarmService {
    private(set) var alarms: [Alarm] = []
    var ringingAlarm: Alarm?

    var isRinging: Bool { ringingAlarm != nil }

    /// Approximate remaining notification slots (iOS max is 64)
    var remainingNotificationSlots: Int {
        let used = alarms.filter(\.isEnabled).reduce(0) { total, alarm in
            let chainsPerTrigger = 3
            if alarm.repeatDays.isEmpty {
                return total + chainsPerTrigger
            } else {
                return total + alarm.repeatDays.count * chainsPerTrigger
            }
        }
        return max(0, 64 - used)
    }

    private let fileURL: URL
    private var audioPlayer: AVAudioPlayer?
    private var volumeRampTimer: Timer?
    private var currentVolume: Float = 0
    nonisolated(unsafe) private var notificationObservers: [Any] = []
    private let soundManager = AlarmNotificationSoundManager.shared

    init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = documentsPath.appendingPathComponent("alarms.json")
        loadAlarms()
        requestNotificationPermission()
        startListeningForNotificationEvents()
    }

    deinit {
        for observer in notificationObservers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - CRUD Operations

    func addAlarm(_ alarm: Alarm) {
        alarms.append(alarm)
        alarms.sort { $0.time < $1.time }
        saveAlarms()
        if alarm.isEnabled {
            scheduleNotifications(for: alarm)
        }
    }

    func updateAlarm(_ alarm: Alarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index] = alarm
            alarms.sort { $0.time < $1.time }
            saveAlarms()

            cancelNotifications(for: alarm)
            if alarm.isEnabled {
                scheduleNotifications(for: alarm)
            }
        }
    }

    func deleteAlarm(_ alarm: Alarm) {
        cancelNotifications(for: alarm)
        alarms.removeAll { $0.id == alarm.id }
        saveAlarms()
    }

    func toggleAlarm(_ alarm: Alarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index].isEnabled.toggle()
            saveAlarms()

            if alarms[index].isEnabled {
                scheduleNotifications(for: alarms[index])
            } else {
                cancelNotifications(for: alarms[index])
            }
        }
    }

    // MARK: - Notification Permission

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Notification Scheduling (with chaining)

    private func scheduleNotifications(for alarm: Alarm) {
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: alarm.time)

        guard let hour = timeComponents.hour, let minute = timeComponents.minute else {
            print("[AlarmService] Invalid time components for alarm: \(alarm.id)")
            return
        }

        // Prepare the custom notification sound
        let notificationSound: UNNotificationSound
        if let cafFilename = soundManager.prepareSound(soundId: alarm.soundId) {
            notificationSound = UNNotificationSound(named: UNNotificationSoundName(rawValue: cafFilename))
        } else {
            notificationSound = .default
        }

        if alarm.repeatDays.isEmpty {
            // One-time alarm: schedule 3 chained notifications
            scheduleChain(
                center: center,
                baseIdentifier: alarm.id.uuidString,
                content: makeContent(for: alarm, sound: notificationSound),
                hour: hour,
                minute: minute,
                weekday: nil,
                repeats: false
            )
        } else {
            // Repeating alarm: schedule 3 chained notifications per weekday
            for day in alarm.repeatDays {
                scheduleChain(
                    center: center,
                    baseIdentifier: "\(alarm.id.uuidString)_day_\(day.rawValue)",
                    content: makeContent(for: alarm, sound: notificationSound),
                    hour: hour,
                    minute: minute,
                    weekday: day.rawValue,
                    repeats: true
                )
            }
        }
    }

    private func scheduleChain(
        center: UNUserNotificationCenter,
        baseIdentifier: String,
        content: UNMutableNotificationContent,
        hour: Int,
        minute: Int,
        weekday: Int?,
        repeats: Bool
    ) {
        let chainOffsets: [(index: Int, seconds: Int)] = [
            (0, 0),    // T+0s
            (1, 30),   // T+30s
            (2, 60),   // T+60s
        ]

        for chain in chainOffsets {
            let identifier = "\(baseIdentifier)_chain_\(chain.index)"

            // Calculate the offset time
            let totalSeconds = minute * 60 + chain.seconds
            let adjustedMinute = (totalSeconds / 60) % 60
            let hourCarry = totalSeconds / 3600
            let adjustedHour = (hour + hourCarry) % 24

            var dateComponents = DateComponents()
            dateComponents.hour = adjustedHour
            dateComponents.minute = adjustedMinute
            dateComponents.second = chain.seconds % 60

            if let weekday = weekday {
                dateComponents.weekday = weekday
            }

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: repeats)
            let contentCopy = content.mutableCopy() as! UNMutableNotificationContent
            let request = UNNotificationRequest(identifier: identifier, content: contentCopy, trigger: trigger)
            center.add(request) { error in
                if let error = error {
                    print("Failed to schedule \(identifier): \(error.localizedDescription)")
                }
            }
        }
    }

    private func makeContent(for alarm: Alarm, sound: UNNotificationSound) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = alarm.label
        content.body = "Time to wake up!"
        content.sound = sound
        content.categoryIdentifier = "ALARM_CATEGORY"
        content.interruptionLevel = .timeSensitive
        content.userInfo = ["alarmId": alarm.id.uuidString]
        return content
    }

    // MARK: - Cancel Notifications (prefix-based)

    private func cancelNotifications(for alarm: Alarm) {
        let center = UNUserNotificationCenter.current()
        let prefix = alarm.id.uuidString

        center.getPendingNotificationRequests { requests in
            let matching = requests.map(\.identifier).filter { $0.hasPrefix(prefix) }
            if !matching.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: matching)
            }
        }
    }

    // MARK: - Alarm Sound Playback with Gradual Volume

    func playAlarmSound(alarm: Alarm) {
        // Stop any existing audio without clearing ringing state
        stopAudioPlayback()

        let sounds = LocalSoundDataSource.shared.getAllSounds()
        guard let sound = sounds.first(where: { $0.id == alarm.soundId }),
              let url = Bundle.main.url(
                  forResource: sound.fileName.replacingOccurrences(of: ".mp3", with: ""),
                  withExtension: "mp3"
              ) else {
            print("Alarm sound not found: \(alarm.soundId)")
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.volume = 0
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()

            startVolumeRamp(durationMinutes: alarm.volumeRampMinutes)
        } catch {
            print("Failed to play alarm sound: \(error.localizedDescription)")
        }
    }

    private func startVolumeRamp(durationMinutes: Int) {
        currentVolume = 0
        let durationSeconds = Double(durationMinutes * 60)
        let stepInterval: Double = 1.0
        let volumeStep = Float(1.0 / (durationSeconds / stepInterval))

        volumeRampTimer?.invalidate()
        volumeRampTimer = Timer.scheduledTimer(withTimeInterval: stepInterval, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self = self else {
                    timer.invalidate()
                    return
                }

                self.currentVolume = min(1.0, self.currentVolume + volumeStep)
                self.audioPlayer?.volume = self.currentVolume

                if self.currentVolume >= 1.0 {
                    timer.invalidate()
                }
            }
        }
    }

    /// Stops audio playback and volume ramp without clearing ringing state
    private func stopAudioPlayback() {
        volumeRampTimer?.invalidate()
        volumeRampTimer = nil
        audioPlayer?.stop()
        audioPlayer = nil
        currentVolume = 0
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    /// Fully stops the alarm: cancels notifications, stops audio, dismisses ringing UI
    func stopAlarmSound() {
        if let alarm = ringingAlarm {
            cancelNotifications(for: alarm)
        }

        stopAudioPlayback()
        ringingAlarm = nil
    }

    // MARK: - Snooze

    func snoozeAlarm(_ alarm: Alarm) {
        stopAlarmSound()

        let center = UNUserNotificationCenter.current()

        // Prepare custom sound for snooze notifications too
        let notificationSound: UNNotificationSound
        if let cafFilename = soundManager.prepareSound(soundId: alarm.soundId) {
            notificationSound = UNNotificationSound(named: UNNotificationSoundName(rawValue: cafFilename))
        } else {
            notificationSound = .default
        }

        // Schedule 3 chained snooze notifications
        let snoozeSeconds = Double(alarm.snoozeMinutes * 60)
        let chainOffsets: [(index: Int, seconds: Double)] = [
            (0, snoozeSeconds),
            (1, snoozeSeconds + 30),
            (2, snoozeSeconds + 60),
        ]

        for chain in chainOffsets {
            let content = UNMutableNotificationContent()
            content.title = alarm.label
            content.body = "Snooze ended - Time to wake up!"
            content.sound = notificationSound
            content.categoryIdentifier = "ALARM_CATEGORY"
            content.interruptionLevel = .timeSensitive
            content.userInfo = ["alarmId": alarm.id.uuidString]

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: chain.seconds,
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: "\(alarm.id.uuidString)_snooze_chain_\(chain.index)",
                content: content,
                trigger: trigger
            )

            center.add(request)
        }
    }

    // MARK: - Notification Event Listeners

    private func startListeningForNotificationEvents() {
        // Listen for "alarm fired" (foreground notification arrival)
        let firedObserver = NotificationCenter.default.addObserver(
            forName: AppDelegate.alarmFiredNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handleAlarmFired(notification)
            }
        }

        // Listen for notification action responses (tap, snooze, stop)
        let actionObserver = NotificationCenter.default.addObserver(
            forName: AppDelegate.alarmActionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handleAlarmAction(notification)
            }
        }

        notificationObservers = [firedObserver, actionObserver]
    }

    private func handleAlarmFired(_ notification: Notification) {
        guard let alarmId = notification.userInfo?[AppDelegate.alarmIdKey] as? String,
              let alarm = alarms.first(where: { $0.id.uuidString == alarmId }) else { return }

        // Don't restart if already ringing this alarm (chain_1/chain_2 fire while ringing)
        guard ringingAlarm?.id != alarm.id else { return }

        ringingAlarm = alarm
        playAlarmSound(alarm: alarm)
        disableOneTimeAlarmIfNeeded(alarmId: alarmId)
    }

    private func handleAlarmAction(_ notification: Notification) {
        guard let alarmId = notification.userInfo?[AppDelegate.alarmIdKey] as? String,
              let actionRaw = notification.userInfo?[AppDelegate.actionTypeKey] as? String,
              let action = AppDelegate.AlarmActionType(rawValue: actionRaw) else { return }

        let alarm = alarms.first(where: { $0.id.uuidString == alarmId })

        switch action {
        case .fired:
            if let alarm = alarm {
                ringingAlarm = alarm
                playAlarmSound(alarm: alarm)
                disableOneTimeAlarmIfNeeded(alarmId: alarmId)
            }
        case .snooze:
            if let alarm = alarm {
                snoozeAlarm(alarm)
            }
        case .stop:
            stopAlarmSound()
            disableOneTimeAlarmIfNeeded(alarmId: alarmId)
        }
    }

    // MARK: - One-Time Alarm Auto-Disable

    private func disableOneTimeAlarmIfNeeded(alarmId: String) {
        guard let index = alarms.firstIndex(where: { $0.id.uuidString == alarmId }),
              alarms[index].repeatDays.isEmpty,
              alarms[index].isEnabled else { return }

        alarms[index].isEnabled = false
        saveAlarms()
    }

    // MARK: - Persistence

    private func loadAlarms() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            alarms = try decoder.decode([Alarm].self, from: data)
            alarms.sort { $0.time < $1.time }
        } catch {
            print("Error loading alarms: \(error)")
        }
    }

    private func saveAlarms() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(alarms)
            try data.write(to: fileURL)
        } catch {
            print("Error saving alarms: \(error)")
        }
    }
}
