import Foundation
import AVFoundation
import SwiftUI

@Observable
@MainActor
final class SleepRecordingService {
    private(set) var status: RecordingStatus = .idle
    private(set) var currentDecibels: Float = 0
    private(set) var peakDecibels: Float = 0
    private(set) var recordingDuration: TimeInterval = 0
    private(set) var recordings: [SleepRecording] = []
    var currentRecording: SleepRecording?

    private let fileURL: URL
    private let recordingsDirectory: URL
    private var audioRecorder: AVAudioRecorder?
    private var meteringTimer: Timer?
    private var decibelSamples: [Float] = []
    private var recentSamples: [Float] = []
    private var recordingStartDate: Date?
    private var previousAudioCategory: AVAudioSession.Category?
    nonisolated(unsafe) private var interruptionObserver: Any?

    init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = documentsPath.appendingPathComponent("sleep_recordings.json")
        recordingsDirectory = documentsPath.appendingPathComponent("SleepRecordings")
        createRecordingsDirectoryIfNeeded()
        loadRecordings()
        startListeningForInterruptions()
    }

    deinit {
        if let observer = interruptionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Microphone Permission

    func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    var microphonePermissionGranted: Bool {
        AVAudioSession.sharedInstance().recordPermission == .granted
    }

    // MARK: - Recording Lifecycle

    func startRecording() {
        guard status == .idle else { return }

        // Save previous audio session category
        previousAudioCategory = AVAudioSession.sharedInstance().category

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Error configuring audio session for recording: \(error)")
            return
        }

        let fileName = "sleep_\(Date().timeIntervalSince1970).m4a"
        let audioFileURL = recordingsDirectory.appendingPathComponent(fileName)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 22050,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
            AVEncoderBitRateKey: 32000
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFileURL, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
        } catch {
            print("Error starting audio recorder: \(error)")
            restoreAudioSession()
            return
        }

        recordingStartDate = Date()
        decibelSamples = []
        recentSamples = []
        peakDecibels = 0
        currentDecibels = 0
        recordingDuration = 0
        status = .recording

        startMeteringTimer()
    }

    func stopRecording() {
        guard status == .recording, let recorder = audioRecorder else { return }

        meteringTimer?.invalidate()
        meteringTimer = nil

        recorder.stop()

        let endDate = Date()
        let duration = recorder.currentTime > 0 ? recorder.currentTime : (recordingStartDate.map { endDate.timeIntervalSince($0) } ?? 0)
        let audioFileURL = recorder.url

        audioRecorder = nil
        restoreAudioSession()

        // Calculate average decibels
        let avgDecibels = decibelSamples.isEmpty ? 0 : decibelSamples.reduce(0, +) / Float(decibelSamples.count)

        var recording = SleepRecording(
            date: recordingStartDate ?? endDate,
            endDate: endDate,
            duration: duration,
            fileURL: audioFileURL,
            decibelSamples: decibelSamples,
            averageDecibels: avgDecibels,
            peakDecibels: peakDecibels,
            snoreScore: 0
        )

        status = .analyzing

        // Run analysis
        let detector = SoundEventDetector()
        let result = detector.analyze(
            samples: decibelSamples,
            recordingDuration: duration,
            startDate: recordingStartDate ?? endDate
        )

        recording.events = result.events
        recording.snoreScore = result.snoreScore

        recordings.insert(recording, at: 0)
        currentRecording = recording
        saveRecordings()

        status = .complete
    }

    func deleteRecording(_ recording: SleepRecording) {
        // Remove audio file
        try? FileManager.default.removeItem(at: recording.fileURL)

        // Remove from array
        recordings.removeAll { $0.id == recording.id }
        saveRecordings()

        if currentRecording?.id == recording.id {
            currentRecording = nil
        }
    }

    func resetStatus() {
        if status == .complete {
            status = .idle
        }
    }

    // MARK: - Storage

    var totalStorageUsed: Int64 {
        recordings.reduce(0) { total, recording in
            let size = (try? FileManager.default.attributesOfItem(atPath: recording.fileURL.path)[.size] as? Int64) ?? 0
            return total + size
        }
    }

    var formattedStorageUsed: String {
        let bytes = totalStorageUsed
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    // MARK: - Metering

    private func startMeteringTimer() {
        meteringTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMetering()
            }
        }
    }

    private func updateMetering() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }

        recorder.updateMeters()
        let power = recorder.averagePower(forChannel: 0)

        // Convert from dBFS (-160 to 0) to approximate dB SPL (0 to ~100)
        let normalizedDB = max(0, power + 160) * (100.0 / 160.0)
        currentDecibels = normalizedDB

        if normalizedDB > peakDecibels {
            peakDecibels = normalizedDB
        }

        recentSamples.append(normalizedDB)

        // Every 1 second (10 samples), average and store
        if recentSamples.count >= 10 {
            let average = recentSamples.reduce(0, +) / Float(recentSamples.count)
            decibelSamples.append(average)
            recentSamples.removeAll()
        }

        recordingDuration = recorder.currentTime
    }

    // MARK: - Audio Session Management

    private func restoreAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            let category = previousAudioCategory ?? .playback
            try session.setCategory(category, mode: .default)
            try session.setActive(true)
        } catch {
            print("Error restoring audio session: \(error)")
        }
        previousAudioCategory = nil
    }

    // MARK: - Interruption Handling

    private func startListeningForInterruptions() {
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handleInterruption(notification)
            }
        }
    }

    private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            audioRecorder?.pause()
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                audioRecorder?.record()
            }
        @unknown default:
            break
        }
    }

    // MARK: - Persistence

    private func createRecordingsDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: recordingsDirectory.path) {
            try? FileManager.default.createDirectory(at: recordingsDirectory, withIntermediateDirectories: true)
        }
    }

    private func loadRecordings() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            recordings = try decoder.decode([SleepRecording].self, from: data)
            recordings.sort { $0.date > $1.date }
        } catch {
            print("Error loading recordings: \(error)")
        }
    }

    private func saveRecordings() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(recordings)
            try data.write(to: fileURL)
        } catch {
            print("Error saving recordings: \(error)")
        }
    }
}
