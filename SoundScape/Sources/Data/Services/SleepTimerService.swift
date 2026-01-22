import Foundation

@Observable
@MainActor
final class SleepTimerService {
    // MARK: - Published State

    private(set) var isActive: Bool = false
    private(set) var remainingSeconds: Int = 0
    private(set) var totalSeconds: Int = 0

    // MARK: - Private Properties

    private var timer: Timer?
    private var originalVolumes: [String: Float] = [:]
    private let audioEngine: AudioEngine
    private var analyticsService: AnalyticsService?

    // MARK: - Computed Properties

    var remainingTimeFormatted: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(remainingSeconds) / Double(totalSeconds)
    }

    // MARK: - Initialization

    init(audioEngine: AudioEngine) {
        self.audioEngine = audioEngine
    }

    func setAnalyticsService(_ service: AnalyticsService) {
        self.analyticsService = service
    }

    // MARK: - Public Methods

    func start(minutes: Int) {
        cancel()
        totalSeconds = minutes * 60
        remainingSeconds = totalSeconds
        isActive = true

        // Log analytics event
        analyticsService?.logSleepTimerStarted(durationMinutes: minutes)

        // Store original volumes for fade calculation
        for activeSound in audioEngine.activeSounds {
            originalVolumes[activeSound.id] = activeSound.volume
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func cancel() {
        if isActive {
            analyticsService?.logSleepTimerCancelled()
        }

        timer?.invalidate()
        timer = nil
        isActive = false
        remainingSeconds = 0
        totalSeconds = 0

        // Restore original volumes if timer was cancelled during fade
        for (soundId, volume) in originalVolumes {
            audioEngine.setVolume(volume, for: soundId)
        }
        originalVolumes.removeAll()
    }

    // MARK: - Private Methods

    private func tick() {
        guard remainingSeconds > 0 else { return }

        remainingSeconds -= 1

        // Start fading volume during last 30 seconds
        if remainingSeconds <= 30 && remainingSeconds > 0 {
            let fadeProgress = Float(remainingSeconds) / 30.0
            for activeSound in audioEngine.activeSounds {
                let originalVolume = originalVolumes[activeSound.id] ?? activeSound.volume
                audioEngine.setVolume(originalVolume * fadeProgress, for: activeSound.id)
            }
        }

        // Timer complete - stop all sounds and record session
        if remainingSeconds <= 0 {
            let timerDuration = TimeInterval(totalSeconds)
            let timerMinutes = totalSeconds / 60

            // Log timer completed event
            analyticsService?.logSleepTimerCompleted(durationMinutes: timerMinutes)

            audioEngine.stopAllFromTimer(timerDuration: timerDuration)
            timer?.invalidate()
            timer = nil
            isActive = false
            totalSeconds = 0
            originalVolumes.removeAll()
        }
    }
}
