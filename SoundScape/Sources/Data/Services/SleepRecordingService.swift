import AVFoundation
import Foundation
import SwiftUI

@Observable
@MainActor
final class SleepRecordingService {
    // MARK: - Observable State

    private(set) var status: RecordingStatus = .idle
    private(set) var currentDecibels: Float = 0
    private(set) var peakDecibels: Float = 0
    private(set) var recordingDuration: TimeInterval = 0
    private(set) var recordings: [SleepRecording] = []
    var currentRecording: SleepRecording?

    // Playback state for highlights
    private(set) var isPlayingHighlight: Bool = false
    private(set) var playingEventId: UUID?
    private(set) var highlightPlaybackProgress: TimeInterval = 0

    // Delay recording
    private(set) var delayRemaining: TimeInterval?

    // Storage
    var totalStorageUsed: Int64 {
        recordings.reduce(0) { total, recording in
            let fileSize = (try? FileManager.default.attributesOfItem(atPath: recording.fileURL.path)[.size] as? Int64) ?? 0
            return total + fileSize
        }
    }

    var formattedStorageUsed: String {
        let bytes = totalStorageUsed
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    // MARK: - Private Properties

    private var audioRecorder: AVAudioRecorder?
    private var meteringTimer: Timer?
    private var durationTimer: Timer?
    private var delayTimer: Timer?
    private var decibelSamples: [Float] = []
    private var recentDecibelReadings: [Float] = []
    private var recordingStartDate: Date?
    private var previousAudioCategory: AVAudioSession.Category?
    private var previousAudioOptions: AVAudioSession.CategoryOptions?
    private var audioPlayer: AVAudioPlayer?
    private var highlightStopTimer: Timer?

    private let fileManager = FileManager.default
    private let metadataFileURL: URL
    private let recordingsDirectory: URL

    // MARK: - Initialization

    init() {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        recordingsDirectory = documentsPath.appendingPathComponent("SleepRecordings")
        metadataFileURL = documentsPath.appendingPathComponent("sleep_recordings.json")

        // Create recordings directory if needed
        if !fileManager.fileExists(atPath: recordingsDirectory.path) {
            try? fileManager.createDirectory(at: recordingsDirectory, withIntermediateDirectories: true)
        }

        loadRecordings()
    }

    // MARK: - Microphone Permission

    func requestMicrophonePermission() async -> Bool {
        if #available(iOS 17.0, *) {
            return await AVAudioApplication.requestRecordPermission()
        } else {
            return await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    var microphonePermissionStatus: Bool {
        AVAudioSession.sharedInstance().recordPermission == .granted
    }

    // MARK: - Recording Methods

    func startRecording() {
        guard status == .idle else { return }

        let session = AVAudioSession.sharedInstance()

        // Save current audio session configuration
        previousAudioCategory = session.category
        previousAudioOptions = session.categoryOptions

        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
            try session.setActive(true)
        } catch {
            print("[SleepRecordingService] Failed to configure audio session: \(error)")
            return
        }

        // Create audio file
        let fileName = "sleep_\(Int(Date().timeIntervalSince1970)).m4a"
        let fileURL = recordingsDirectory.appendingPathComponent(fileName)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 22050.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.low.rawValue,
            AVEncoderBitRateKey: 32000,
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
        } catch {
            print("[SleepRecordingService] Failed to create recorder: \(error)")
            restoreAudioSession()
            return
        }

        // Reset state
        recordingStartDate = Date()
        decibelSamples = []
        recentDecibelReadings = []
        peakDecibels = 0
        currentDecibels = 0
        recordingDuration = 0
        status = .recording

        // Start metering timer (10Hz)
        meteringTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMetering()
            }
        }

        // Start duration timer (1Hz)
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateDuration()
            }
        }
    }

    func stopRecording() {
        guard status == .recording, let recorder = audioRecorder else { return }

        let fileURL = recorder.url
        let endDate = Date()
        let duration = recorder.currentTime

        recorder.stop()
        audioRecorder = nil
        meteringTimer?.invalidate()
        meteringTimer = nil
        durationTimer?.invalidate()
        durationTimer = nil

        restoreAudioSession()

        // Calculate averages
        let avgDecibels = decibelSamples.isEmpty ? 0 : decibelSamples.reduce(0, +) / Float(decibelSamples.count)

        // Create recording
        var recording = SleepRecording(
            date: recordingStartDate ?? endDate.addingTimeInterval(-duration),
            endDate: endDate,
            duration: duration,
            fileURL: fileURL,
            decibelSamples: decibelSamples,
            averageDecibels: avgDecibels,
            peakDecibels: peakDecibels
        )

        status = .analyzing

        // Run analysis
        let detector = SoundEventDetector()
        let samples = decibelSamples
        let startDate = recordingStartDate ?? endDate.addingTimeInterval(-duration)

        Task {
            let result = await Task.detached(priority: .userInitiated) {
                detector.analyze(samples: samples, recordingDuration: duration, startDate: startDate)
            }.value

            recording.events = result.events
            recording.snoreScore = result.snoreScore

            self.recordings.insert(recording, at: 0)
            self.currentRecording = recording
            self.saveRecordings()
            self.status = .complete
        }
    }

    func deleteRecording(_ recording: SleepRecording) {
        // Remove audio file
        try? fileManager.removeItem(at: recording.fileURL)

        // Remove from list
        recordings.removeAll { $0.id == recording.id }
        saveRecordings()
    }

    func dismissReport() {
        currentRecording = nil
        status = .idle
    }

    // MARK: - Delayed Recording

    func startRecordingWithDelay(minutes: Int) {
        guard status == .idle else { return }
        delayRemaining = TimeInterval(minutes * 60)

        delayTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                if let remaining = self.delayRemaining {
                    let newRemaining = remaining - 1
                    if newRemaining <= 0 {
                        self.delayRemaining = nil
                        timer.invalidate()
                        self.delayTimer = nil
                        self.startRecording()
                    } else {
                        self.delayRemaining = newRemaining
                    }
                }
            }
        }
    }

    func cancelDelay() {
        delayTimer?.invalidate()
        delayTimer = nil
        delayRemaining = nil
    }

    func startRecordingWhenTimerEnds(sleepTimerService: SleepTimerService) {
        // Poll the timer service until it finishes
        delayTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                if !sleepTimerService.isActive {
                    timer.invalidate()
                    self.delayTimer = nil
                    self.delayRemaining = nil
                    self.startRecording()
                } else {
                    self.delayRemaining = TimeInterval(sleepTimerService.remainingSeconds)
                }
            }
        }
    }

    // MARK: - Highlight Playback

    func playHighlight(recording: SleepRecording, event: SoundEvent) {
        stopPlayback()

        guard fileManager.fileExists(atPath: recording.fileURL.path) else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: recording.fileURL)
            audioPlayer?.prepareToPlay()

            // Seek to event timestamp with 1.5s buffer before
            let startTime = max(0, event.timestamp - 1.5)
            audioPlayer?.currentTime = startTime
            audioPlayer?.play()

            isPlayingHighlight = true
            playingEventId = event.id
            highlightPlaybackProgress = 0

            // Stop after event duration + 3 seconds buffer
            let playDuration = event.duration + 3.0
            highlightStopTimer = Timer.scheduledTimer(withTimeInterval: playDuration, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    self?.stopPlayback()
                }
            }
        } catch {
            print("[SleepRecordingService] Failed to play highlight: \(error)")
        }
    }

    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        highlightStopTimer?.invalidate()
        highlightStopTimer = nil
        isPlayingHighlight = false
        playingEventId = nil
        highlightPlaybackProgress = 0
    }

    // MARK: - Export

    func generateReportText(for recording: SleepRecording) -> String {
        var report = """
        SoundScape Sleep Report
        Date: \(recording.formattedDate)
        Time: \(recording.formattedTimeRange)
        Duration: \(recording.formattedDuration)
        Snore Score: \(recording.snoreScore)/100 (\(recording.snoreScoreCategory))

        Summary:
        - Snoring: \(recording.snoringMinutes) minutes across \(recording.events.filter { $0.type == .snoring }.count) episodes
        - Peak volume: \(Int(recording.peakDecibels)) dB
        """

        if let loudest = recording.events.filter({ $0.type != .silence }).max(by: { $0.peakDecibels < $1.peakDecibels }) {
            report += "\n- Loudest event: \(loudest.formattedDuration) at \(loudest.formattedTimestamp) (\(Int(loudest.peakDecibels)) dB)"
        }

        if !recording.events.isEmpty {
            report += "\n\nEvents:"
            for event in recording.events.filter({ $0.type != .silence }).sorted(by: { $0.timestamp < $1.timestamp }) {
                report += "\n\(event.formattedTimestamp) - \(event.type.displayName) (\(event.formattedDuration), \(Int(event.peakDecibels)) dB)"
            }
        }

        report += "\n\nNote: This report was generated by SoundScape and is not a medical diagnosis."

        return report
    }

    // MARK: - Private Methods

    private func updateMetering() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }
        recorder.updateMeters()

        // AVAudioRecorder returns dB in range roughly -160 to 0
        let power = recorder.averagePower(forChannel: 0)
        // Normalize to positive dB scale (0-120)
        let normalizedDb = max(0, power + 120) * 0.75 // Maps -120..0 to 0..90 roughly

        currentDecibels = normalizedDb
        recentDecibelReadings.append(normalizedDb)

        if normalizedDb > peakDecibels {
            peakDecibels = normalizedDb
        }
    }

    private func updateDuration() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }
        recordingDuration = recorder.currentTime

        // Aggregate recent readings into a single per-second sample
        if !recentDecibelReadings.isEmpty {
            let average = recentDecibelReadings.reduce(0, +) / Float(recentDecibelReadings.count)
            decibelSamples.append(average)
            recentDecibelReadings = []
        }
    }

    private func restoreAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            let category = previousAudioCategory ?? .playback
            let options = previousAudioOptions ?? []
            try session.setCategory(category, options: options)
        } catch {
            print("[SleepRecordingService] Failed to restore audio session: \(error)")
        }
    }

    // MARK: - Persistence

    private func loadRecordings() {
        guard fileManager.fileExists(atPath: metadataFileURL.path) else { return }
        do {
            let data = try Data(contentsOf: metadataFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            recordings = try decoder.decode([SleepRecording].self, from: data)
            recordings.sort { $0.date > $1.date }
        } catch {
            print("[SleepRecordingService] Error loading recordings: \(error)")
        }
    }

    private func saveRecordings() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(recordings)
            try data.write(to: metadataFileURL)
        } catch {
            print("[SleepRecordingService] Error saving recordings: \(error)")
        }
    }
}
