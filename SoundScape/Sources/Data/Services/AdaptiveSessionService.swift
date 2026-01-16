import Foundation

@Observable
@MainActor
final class AdaptiveSessionService {
    // MARK: - State

    private(set) var isActive: Bool = false
    private(set) var currentMode: AdaptiveMode?
    private(set) var currentPhaseIndex: Int = 0
    private(set) var phaseTimeRemaining: Int = 0  // seconds

    private var phaseTimer: Timer?
    private let audioEngine: AudioEngine
    private let soundRepository: SoundRepository

    // MARK: - Computed Properties

    var currentPhase: AdaptivePhase? {
        guard let mode = currentMode, currentPhaseIndex < mode.phases.count else { return nil }
        return mode.phases[currentPhaseIndex]
    }

    var totalDuration: Int {
        currentMode?.phases.reduce(0) { $0 + $1.duration } ?? 0
    }

    var elapsedTime: Int {
        guard let mode = currentMode else { return 0 }
        var elapsed = 0
        for i in 0..<currentPhaseIndex {
            elapsed += mode.phases[i].duration * 60
        }
        if let phase = currentPhase {
            elapsed += (phase.duration * 60) - phaseTimeRemaining
        }
        return elapsed
    }

    var totalTimeInSeconds: Int {
        totalDuration * 60
    }

    var progress: Double {
        guard totalTimeInSeconds > 0 else { return 0 }
        return Double(elapsedTime) / Double(totalTimeInSeconds)
    }

    var phaseProgress: Double {
        guard let phase = currentPhase else { return 0 }
        let totalPhaseTime = phase.duration * 60
        guard totalPhaseTime > 0 else { return 0 }
        return Double(totalPhaseTime - phaseTimeRemaining) / Double(totalPhaseTime)
    }

    // MARK: - Initialization

    init(audioEngine: AudioEngine, soundRepository: SoundRepository = SoundRepository()) {
        self.audioEngine = audioEngine
        self.soundRepository = soundRepository
    }

    // MARK: - Public Methods

    func start(mode: AdaptiveMode) {
        stop()
        currentMode = mode
        currentPhaseIndex = 0
        isActive = true
        startPhase()
    }

    func stop() {
        phaseTimer?.invalidate()
        phaseTimer = nil
        audioEngine.stopAll()
        isActive = false
        currentMode = nil
        currentPhaseIndex = 0
        phaseTimeRemaining = 0
    }

    // MARK: - Private Methods

    private func startPhase() {
        guard let phase = currentPhase else {
            stop()
            return
        }

        phaseTimeRemaining = phase.duration * 60

        // Transition sounds
        transitionToPhase(phase)

        // Start phase timer
        phaseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func tick() {
        phaseTimeRemaining -= 1
        if phaseTimeRemaining <= 0 {
            advancePhase()
        }
    }

    private func advancePhase() {
        phaseTimer?.invalidate()
        currentPhaseIndex += 1

        guard let mode = currentMode, currentPhaseIndex < mode.phases.count else {
            // Session complete
            stop()
            return
        }

        startPhase()
    }

    private func transitionToPhase(_ phase: AdaptivePhase) {
        // Stop all current sounds
        audioEngine.stopAll()

        // Start new sounds with specified volumes
        for (soundId, volume) in phase.sounds {
            if let sound = soundRepository.getSound(byId: soundId) {
                audioEngine.play(sound: sound)
                // Small delay to ensure sound is playing before setting volume
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.audioEngine.setVolume(volume, for: soundId)
                }
            }
        }
    }
}
