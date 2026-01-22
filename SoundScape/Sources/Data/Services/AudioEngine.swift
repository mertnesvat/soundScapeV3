import AVFoundation
import Foundation
import MediaPlayer

@Observable
@MainActor
final class AudioEngine: AudioPlayerProtocol {
    // MARK: - Properties

    private var players: [String: AVAudioPlayer] = [:]
    private(set) var activeSounds: [ActiveSound] = []

    // Session tracking for insights
    private var sessionStartTime: Date?
    private var insightsService: InsightsService?
    private var analyticsService: AnalyticsService?

    // Track sound start times for analytics
    private var soundStartTimes: [String: Date] = [:]

    // Track if we were playing before an interruption
    private var wasPlayingBeforeInterruption = false

    var isAnyPlaying: Bool {
        activeSounds.contains { $0.isPlaying }
    }

    // MARK: - Initialization

    init() {
        configureAudioSession()
        setupInterruptionHandling()
        setupRemoteCommandCenter()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Insights Service Injection

    func setInsightsService(_ service: InsightsService) {
        self.insightsService = service
    }

    func setAnalyticsService(_ service: AnalyticsService) {
        self.analyticsService = service
    }

    // MARK: - Audio Session Configuration

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            // Use .playback category without .mixWithOthers to enable:
            // - Background audio playback
            // - Now Playing controls on lock screen
            // - Remote command center support
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            print("Audio session configuration error: \(error.localizedDescription)")
        }
    }

    // MARK: - Interruption Handling

    private func setupInterruptionHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    @objc private func handleAudioInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        Task { @MainActor in
            switch type {
            case .began:
                // Interruption began (phone call, Siri, etc.)
                wasPlayingBeforeInterruption = isAnyPlaying
                if wasPlayingBeforeInterruption {
                    pauseAll()
                }

            case .ended:
                // Interruption ended - check if we should resume
                guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else {
                    return
                }
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)

                if options.contains(.shouldResume) && wasPlayingBeforeInterruption {
                    // Reactivate audio session and resume playback
                    do {
                        try AVAudioSession.sharedInstance().setActive(true)
                        resumeAll()
                    } catch {
                        print("Failed to reactivate audio session: \(error.localizedDescription)")
                    }
                }
                wasPlayingBeforeInterruption = false

            @unknown default:
                break
            }
        }
    }

    // MARK: - Remote Command Center

    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()

        // Play command - triggered from lock screen/Control Center play button
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            Task { @MainActor in
                self.resumeAll()
            }
            return .success
        }

        // Pause command - triggered from lock screen/Control Center pause button
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            Task { @MainActor in
                self.pauseAll()
            }
            return .success
        }

        // Toggle play/pause command - triggered by headphone button
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            Task { @MainActor in
                if self.isAnyPlaying {
                    self.pauseAll()
                } else {
                    self.resumeAll()
                }
            }
            return .success
        }
    }

    // MARK: - Playback Controls

    func play(sound: Sound) {
        // If sound is already active, just resume it
        if let index = activeSounds.firstIndex(where: { $0.id == sound.id }) {
            if !activeSounds[index].isPlaying {
                resume(soundId: sound.id)
            }
            return
        }

        // Load audio file from bundle
        guard let url = Bundle.main.url(forResource: sound.fileName.replacingOccurrences(of: ".mp3", with: ""), withExtension: "mp3") else {
            print("Audio file not found: \(sound.fileName)")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1  // Infinite looping
            player.volume = 0.7        // Default volume
            player.prepareToPlay()

            // Fade in effect
            player.volume = 0
            player.play()
            fadeIn(player: player, targetVolume: 0.7, duration: 0.5)

            players[sound.id] = player

            let activeSound = ActiveSound(
                id: sound.id,
                sound: sound,
                volume: 0.7,
                isPlaying: true
            )
            activeSounds.append(activeSound)

            // Start session tracking if this is the first sound
            if sessionStartTime == nil {
                sessionStartTime = Date()
                insightsService?.startSession()
            }

            // Track sound start time and log analytics
            soundStartTimes[sound.id] = Date()
            analyticsService?.logSoundStarted(soundId: sound.id, soundName: sound.name, category: sound.category.rawValue)

            // Log mix started if multiple sounds
            if activeSounds.count > 1 {
                let soundNames = activeSounds.map { $0.sound.name }
                analyticsService?.logMixStarted(soundCount: activeSounds.count, soundNames: soundNames)
            }

            // Update Now Playing info on lock screen
            updateNowPlayingInfo()
        } catch {
            print("Error creating audio player: \(error.localizedDescription)")
        }
    }

    func pause(soundId: String) {
        guard let player = players[soundId],
              let index = activeSounds.firstIndex(where: { $0.id == soundId }) else {
            return
        }

        // Fade out before pausing
        fadeOut(player: player, duration: 0.3) { [weak self] in
            player.pause()
            self?.activeSounds[index].isPlaying = false
            // Update Now Playing info after pause
            self?.updateNowPlayingInfo()
        }
    }

    func resume(soundId: String) {
        guard let player = players[soundId],
              let index = activeSounds.firstIndex(where: { $0.id == soundId }) else {
            return
        }

        let targetVolume = activeSounds[index].volume
        player.volume = 0
        player.play()
        fadeIn(player: player, targetVolume: targetVolume, duration: 0.3)
        activeSounds[index].isPlaying = true

        // Update Now Playing info after resume
        updateNowPlayingInfo()
    }

    func stop(soundId: String) {
        guard let player = players[soundId] else { return }

        // Log analytics for sound stopped
        if let startTime = soundStartTimes[soundId],
           let activeSound = activeSounds.first(where: { $0.id == soundId }) {
            let duration = Date().timeIntervalSince(startTime)
            analyticsService?.logSoundStopped(soundId: soundId, soundName: activeSound.sound.name, duration: duration)
            soundStartTimes.removeValue(forKey: soundId)
        }

        // Fade out before stopping
        fadeOut(player: player, duration: 0.3) { [weak self] in
            player.stop()
            self?.players.removeValue(forKey: soundId)
            self?.activeSounds.removeAll { $0.id == soundId }
            // Update Now Playing info after removing sound
            self?.updateNowPlayingInfo()
        }
    }

    func stopAll() {
        // Record session if played for more than 1 minute (manual stop)
        recordSessionIfNeeded()

        for soundId in players.keys {
            stop(soundId: soundId)
        }

        // Clear Now Playing info when all sounds stopped
        clearNowPlayingInfo()
    }

    /// Called by SleepTimerService when timer ends - records session with timer duration
    func stopAllFromTimer(timerDuration: TimeInterval) {
        let soundIds = activeSounds.map { $0.id }
        insightsService?.recordSession(duration: timerDuration, soundsUsed: soundIds)
        sessionStartTime = nil

        for soundId in players.keys {
            stop(soundId: soundId)
        }

        // Clear Now Playing info when timer stops all sounds
        clearNowPlayingInfo()
    }

    private func recordSessionIfNeeded() {
        guard let startTime = sessionStartTime else { return }

        let duration = Date().timeIntervalSince(startTime)
        let minimumDuration: TimeInterval = 60 // 1 minute

        if duration >= minimumDuration {
            let soundIds = activeSounds.map { $0.id }
            insightsService?.recordSession(duration: duration, soundsUsed: soundIds)
        }

        sessionStartTime = nil
    }

    func pauseAll() {
        for activeSound in activeSounds where activeSound.isPlaying {
            pause(soundId: activeSound.id)
        }
        // Update Now Playing info to reflect paused state
        updateNowPlayingInfo()
    }

    func resumeAll() {
        for activeSound in activeSounds where !activeSound.isPlaying {
            resume(soundId: activeSound.id)
        }
        // Update Now Playing info to reflect playing state
        updateNowPlayingInfo()
    }

    func setVolume(_ volume: Float, for soundId: String) {
        guard let player = players[soundId],
              let index = activeSounds.firstIndex(where: { $0.id == soundId }) else {
            return
        }

        let clampedVolume = max(0, min(1, volume))
        player.volume = clampedVolume
        activeSounds[index].volume = clampedVolume
    }

    func isPlaying(soundId: String) -> Bool {
        activeSounds.first { $0.id == soundId }?.isPlaying ?? false
    }

    // MARK: - Fade Effects

    private func fadeIn(player: AVAudioPlayer, targetVolume: Float, duration: TimeInterval) {
        let steps = 20
        let stepDuration = duration / Double(steps)
        let volumeStep = targetVolume / Float(steps)

        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                player.volume = min(targetVolume, volumeStep * Float(i))
            }
        }
    }

    private func fadeOut(player: AVAudioPlayer, duration: TimeInterval, completion: @escaping () -> Void) {
        let steps = 20
        let stepDuration = duration / Double(steps)
        let initialVolume = player.volume
        let volumeStep = initialVolume / Float(steps)

        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                player.volume = max(0, initialVolume - volumeStep * Float(i))
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            completion()
        }
    }

    // MARK: - Now Playing Info Center

    private func updateNowPlayingInfo() {
        guard !activeSounds.isEmpty else {
            clearNowPlayingInfo()
            return
        }

        var nowPlayingInfo = [String: Any]()

        // Title - "SoundScape Mix"
        nowPlayingInfo[MPMediaItemPropertyTitle] = "SoundScape Mix"

        // Subtitle - list of active sound names
        let soundNames = activeSounds.map { $0.sound.name }.joined(separator: ", ")
        nowPlayingInfo[MPMediaItemPropertyArtist] = soundNames

        // Playback state (1.0 = playing, 0.0 = paused)
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isAnyPlaying ? 1.0 : 0.0

        // Artwork - use dedicated Now Playing artwork or system waveform as fallback
        if let image = UIImage(named: "NowPlayingArtwork") ?? UIImage(systemName: "waveform.circle.fill") {
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    private func clearNowPlayingInfo() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    // MARK: - Toggle Convenience

    func togglePlayback(for sound: Sound) {
        if let activeSound = activeSounds.first(where: { $0.id == sound.id }) {
            if activeSound.isPlaying {
                pause(soundId: sound.id)
            } else {
                resume(soundId: sound.id)
            }
        } else {
            play(sound: sound)
        }
    }
}
