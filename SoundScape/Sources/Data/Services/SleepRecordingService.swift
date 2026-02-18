import Foundation
import AVFoundation
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

    // MARK: - Private Properties

    private var audioRecorder: AVAudioRecorder?
    private var meteringTimer: Timer?
    private var durationTimer: Timer?
    private var decibelSamples: [Float] = []
    private var recentMeterValues: [Float] = []
    private var recordingStartDate: Date?
    private var previousAudioCategory: AVAudioSession.Category?
    private var previousAudioOptions: AVAudioSession.CategoryOptions?

    private let fileManager = FileManager.default
    private let metadataURL: URL
    private let recordingsDirectory: URL

    // MARK: - Storage

    var totalStorageUsed: Int64 {
        recordings.compactMap { recording in
            try? fileManager.attributesOfItem(atPath: recording.fileURL.path)[.size] as? Int64
        }.reduce(0, +)
    }

    var formattedStorageUsed: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalStorageUsed)
    }

    // MARK: - Initialization

    init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        recordingsDirectory = documentsPath.appendingPathComponent("SleepRecordings")
        metadataURL = documentsPath.appendingPathComponent("sleep_recordings.json")

        if !fileManager.fileExists(atPath: recordingsDirectory.path) {
            try? fileManager.createDirectory(at: recordingsDirectory, withIntermediateDirectories: true)
        }

        loadRecordings()
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

    // MARK: - Recording Controls

    func startRecording() {
        guard status == .idle else { return }

        let session = AVAudioSession.sharedInstance()

        // Save previous audio session configuration
        previousAudioCategory = session.category
        previousAudioOptions = session.categoryOptions

        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
            try session.setActive(true)
        } catch {
            print("[SleepRecordingService] Failed to configure audio session: \(error)")
            return
        }

        let fileName = "sleep_\(UUID().uuidString).m4a"
        let fileURL = recordingsDirectory.appendingPathComponent(fileName)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 22050,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.low.rawValue,
            AVEncoderBitRateKey: 32000,
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
        } catch {
            print("[SleepRecordingService] Failed to start recording: \(error)")
            restoreAudioSession()
            return
        }

        recordingStartDate = Date()
        decibelSamples = []
        recentMeterValues = []
        peakDecibels = 0
        currentDecibels = 0
        recordingDuration = 0
        status = .recording

        startMetering()
    }

    func stopRecording() {
        guard status == .recording, let recorder = audioRecorder else { return }

        let fileURL = recorder.url
        let startDate = recordingStartDate ?? Date()
        let endDate = Date()
        let duration = endDate.timeIntervalSince(startDate)

        recorder.stop()
        audioRecorder = nil
        stopMetering()
        restoreAudioSession()

        let avgDecibels = decibelSamples.isEmpty ? 0 : decibelSamples.reduce(0, +) / Float(decibelSamples.count)

        let recording = SleepRecording(
            date: startDate,
            endDate: endDate,
            duration: duration,
            fileURL: fileURL,
            events: [],
            decibelSamples: decibelSamples,
            averageDecibels: avgDecibels,
            peakDecibels: peakDecibels,
            snoreScore: 0
        )

        status = .analyzing
        currentRecording = recording

        Task {
            await analyzeRecording(recording)
        }
    }

    func deleteRecording(_ recording: SleepRecording) {
        try? fileManager.removeItem(at: recording.fileURL)
        recordings.removeAll { $0.id == recording.id }
        if currentRecording?.id == recording.id {
            currentRecording = nil
        }
        saveRecordings()
    }

    // MARK: - Analysis Integration

    private func analyzeRecording(_ recording: SleepRecording) async {
        let detector = SoundEventDetector()
        let result = await Task.detached { [decibelSamples = recording.decibelSamples, duration = recording.duration, date = recording.date] in
            detector.analyze(
                samples: decibelSamples,
                recordingDuration: duration,
                startDate: date
            )
        }.value

        var updatedRecording = recording
        updatedRecording.events = result.events
        updatedRecording.snoreScore = result.snoreScore

        recordings.insert(updatedRecording, at: 0)
        currentRecording = updatedRecording
        saveRecordings()
        status = .complete
    }

    // MARK: - Audio Highlight Playback

    private var highlightPlayer: AVAudioPlayer?
    private(set) var isPlayingHighlight: Bool = false
    private(set) var playingEventId: UUID?
    private var highlightStopTimer: Timer?

    func playHighlight(recording: SleepRecording, event: SoundEvent) {
        stopPlayback()

        do {
            highlightPlayer = try AVAudioPlayer(contentsOf: recording.fileURL)
            guard let player = highlightPlayer else { return }

            let startTime = max(0, event.timestamp - 1.5)
            let playDuration = event.duration + 3.0

            player.prepareToPlay()
            player.currentTime = startTime
            player.play()

            isPlayingHighlight = true
            playingEventId = event.id

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
        highlightStopTimer?.invalidate()
        highlightStopTimer = nil
        highlightPlayer?.stop()
        highlightPlayer = nil
        isPlayingHighlight = false
        playingEventId = nil
    }

    // MARK: - Metering

    private func startMetering() {
        meteringTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMetering()
            }
        }

        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateDuration()
            }
        }
    }

    private func stopMetering() {
        meteringTimer?.invalidate()
        meteringTimer = nil
        durationTimer?.invalidate()
        durationTimer = nil
    }

    private func updateMetering() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }

        recorder.updateMeters()
        let power = recorder.averagePower(forChannel: 0)

        // Convert from dBFS (-160 to 0) to a positive dB scale (0-120)
        let normalizedDB = max(0, power + 160) * (120.0 / 160.0)
        currentDecibels = normalizedDB
        recentMeterValues.append(normalizedDB)

        if normalizedDB > peakDecibels {
            peakDecibels = normalizedDB
        }
    }

    private func updateDuration() {
        guard let startDate = recordingStartDate, status == .recording else { return }
        recordingDuration = Date().timeIntervalSince(startDate)

        // Average the recent meter values into one sample per second
        if !recentMeterValues.isEmpty {
            let avgSample = recentMeterValues.reduce(0, +) / Float(recentMeterValues.count)
            decibelSamples.append(avgSample)
            recentMeterValues.removeAll()
        }
    }

    // MARK: - Audio Session

    private func restoreAudioSession() {
        let session = AVAudioSession.sharedInstance()
        let category = previousAudioCategory ?? .playback
        let options = previousAudioOptions ?? []
        do {
            try session.setCategory(category, options: options)
        } catch {
            print("[SleepRecordingService] Failed to restore audio session: \(error)")
        }
        previousAudioCategory = nil
        previousAudioOptions = nil
    }

    // MARK: - Persistence

    private func loadRecordings() {
        guard fileManager.fileExists(atPath: metadataURL.path) else { return }
        do {
            let data = try Data(contentsOf: metadataURL)
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
            try data.write(to: metadataURL)
        } catch {
            print("[SleepRecordingService] Error saving recordings: \(error)")
        }
    }
}
