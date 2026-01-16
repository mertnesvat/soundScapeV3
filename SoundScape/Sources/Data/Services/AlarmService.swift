import Foundation
import UserNotifications
import AVFoundation

@Observable
@MainActor
final class AlarmService {
    private(set) var alarms: [Alarm] = []
    private let fileURL: URL
    private var audioPlayer: AVAudioPlayer?
    private var volumeRampTimer: Timer?
    private var currentVolume: Float = 0

    init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = documentsPath.appendingPathComponent("alarms.json")
        loadAlarms()
        requestNotificationPermission()
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

            // Cancel old notifications and reschedule if enabled
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

    // MARK: - Notification Scheduling

    private func scheduleNotifications(for alarm: Alarm) {
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current

        let content = UNMutableNotificationContent()
        content.title = alarm.label
        content.body = "Time to wake up!"
        content.sound = .default
        content.categoryIdentifier = "ALARM_CATEGORY"

        let timeComponents = calendar.dateComponents([.hour, .minute], from: alarm.time)

        if alarm.repeatDays.isEmpty {
            // One-time alarm
            var dateComponents = DateComponents()
            dateComponents.hour = timeComponents.hour
            dateComponents.minute = timeComponents.minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(
                identifier: alarm.id.uuidString,
                content: content,
                trigger: trigger
            )

            center.add(request) { error in
                if let error = error {
                    print("Failed to schedule notification: \(error.localizedDescription)")
                }
            }
        } else {
            // Repeating alarm for each selected day
            for day in alarm.repeatDays {
                var dateComponents = DateComponents()
                dateComponents.hour = timeComponents.hour
                dateComponents.minute = timeComponents.minute
                dateComponents.weekday = day.rawValue

                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(
                    identifier: "\(alarm.id.uuidString)_\(day.rawValue)",
                    content: content,
                    trigger: trigger
                )

                center.add(request) { error in
                    if let error = error {
                        print("Failed to schedule notification: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func cancelNotifications(for alarm: Alarm) {
        let center = UNUserNotificationCenter.current()

        // Cancel main notification
        var identifiers = [alarm.id.uuidString]

        // Cancel weekday-specific notifications
        for day in Weekday.allCases {
            identifiers.append("\(alarm.id.uuidString)_\(day.rawValue)")
        }

        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    // MARK: - Alarm Sound Playback with Gradual Volume

    func playAlarmSound(alarm: Alarm) {
        stopAlarmSound()

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

            // Start gradual volume ramp
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

    func stopAlarmSound() {
        volumeRampTimer?.invalidate()
        volumeRampTimer = nil
        audioPlayer?.stop()
        audioPlayer = nil
        currentVolume = 0
    }

    func snoozeAlarm(_ alarm: Alarm) {
        stopAlarmSound()

        // Schedule a local notification for snooze duration
        let content = UNMutableNotificationContent()
        content.title = alarm.label
        content.body = "Snooze ended - Time to wake up!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: Double(alarm.snoozeMinutes * 60),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "\(alarm.id.uuidString)_snooze",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
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
