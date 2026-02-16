import Foundation
import AVFoundation

final class AlarmNotificationSoundManager {
    static let shared = AlarmNotificationSoundManager()

    private let soundsDirectoryName = "Sounds"
    private var preparedSounds: Set<String> = []

    private init() {
        loadPreparedSoundsCache()
    }

    // MARK: - Public API

    /// Prepares a 30-second .caf file for a given sound ID.
    /// Returns the filename (e.g. "morning_birds_alarm.caf") suitable for UNNotificationSound(named:),
    /// or nil if preparation fails.
    func prepareSound(soundId: String) -> String? {
        let cafFilename = "\(soundId)_alarm.caf"

        if preparedSounds.contains(soundId) {
            let cafURL = librarySoundsDirectory().appendingPathComponent(cafFilename)
            if FileManager.default.fileExists(atPath: cafURL.path) {
                return cafFilename
            }
        }

        let sounds = LocalSoundDataSource.shared.getAllSounds()
        guard let sound = sounds.first(where: { $0.id == soundId }),
              let sourceURL = Bundle.main.url(
                  forResource: sound.fileName.replacingOccurrences(of: ".mp3", with: ""),
                  withExtension: "mp3"
              ) else {
            print("[AlarmSoundManager] Source MP3 not found for: \(soundId)")
            return nil
        }

        do {
            let outputURL = try convertToCAF(sourceURL: sourceURL, outputFilename: cafFilename, maxDurationSeconds: 30)
            preparedSounds.insert(soundId)
            savePreparedSoundsCache()
            print("[AlarmSoundManager] Prepared: \(outputURL.lastPathComponent)")
            return cafFilename
        } catch {
            print("[AlarmSoundManager] Failed to prepare \(soundId): \(error.localizedDescription)")
            return nil
        }
    }

    /// Batch-prepares all sounds that can be used as alarm tones.
    func prepareAllAlarmSounds() {
        let sounds = LocalSoundDataSource.shared.getAllSounds()
        for sound in sounds {
            _ = prepareSound(soundId: sound.id)
        }
    }

    // MARK: - Audio Conversion

    private func convertToCAF(sourceURL: URL, outputFilename: String, maxDurationSeconds: Double) throws -> URL {
        let outputDir = librarySoundsDirectory()
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        let outputURL = outputDir.appendingPathComponent(outputFilename)

        // Remove existing file if present
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        let sourceFile = try AVAudioFile(forReading: sourceURL)
        let sourceFormat = sourceFile.processingFormat
        let sampleRate = sourceFormat.sampleRate
        let channelCount = sourceFormat.channelCount

        let maxFrames = AVAudioFrameCount(maxDurationSeconds * sampleRate)
        let framesToRead = min(maxFrames, AVAudioFrameCount(sourceFile.length))

        // Create output format: Linear PCM in .caf container
        guard let outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: channelCount,
            interleaved: false
        ) else {
            throw AlarmSoundError.formatCreationFailed
        }

        let outputFile = try AVAudioFile(
            forWriting: outputURL,
            settings: outputFormat.settings,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )

        // Read and write in chunks to avoid loading entire file into memory
        let chunkSize: AVAudioFrameCount = 8192
        var framesWritten: AVAudioFrameCount = 0

        while framesWritten < framesToRead {
            let framesToProcess = min(chunkSize, framesToRead - framesWritten)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: sourceFormat, frameCapacity: framesToProcess) else {
                throw AlarmSoundError.bufferCreationFailed
            }

            try sourceFile.read(into: buffer, frameCount: framesToProcess)
            try outputFile.write(from: buffer)
            framesWritten += framesToProcess
        }

        return outputURL
    }

    // MARK: - File System

    private func librarySoundsDirectory() -> URL {
        let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        return library.appendingPathComponent(soundsDirectoryName)
    }

    // MARK: - Cache Persistence

    private var cacheURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("prepared_alarm_sounds.json")
    }

    private func loadPreparedSoundsCache() {
        guard let data = try? Data(contentsOf: cacheURL),
              let cached = try? JSONDecoder().decode(Set<String>.self, from: data) else { return }
        preparedSounds = cached
    }

    private func savePreparedSoundsCache() {
        guard let data = try? JSONEncoder().encode(preparedSounds) else { return }
        try? data.write(to: cacheURL)
    }
}

// MARK: - Errors

enum AlarmSoundError: LocalizedError {
    case formatCreationFailed
    case bufferCreationFailed

    var errorDescription: String? {
        switch self {
        case .formatCreationFailed: return "Failed to create audio format"
        case .bufferCreationFailed: return "Failed to create audio buffer"
        }
    }
}
