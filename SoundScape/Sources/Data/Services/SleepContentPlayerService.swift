import AVFoundation
import Foundation
import MediaPlayer

/// Service for playing sleep content audio (yoga nidra, stories, meditations, etc.)
/// This is separate from AudioEngine as sleep content is single-track and non-looping
@Observable
@MainActor
final class SleepContentPlayerService: NSObject {
    // MARK: - Properties

    private var player: AVAudioPlayer?
    private var progressTimer: Timer?
    private var progressService: StoryProgressService?

    /// Currently playing content
    private(set) var currentContent: SleepContent?

    /// Whether audio is currently playing
    private(set) var isPlaying = false

    /// Current playback position in seconds
    private(set) var currentTime: TimeInterval = 0

    /// Total duration of current content in seconds
    private(set) var duration: TimeInterval = 0

    /// Track if we were playing before an interruption
    private var wasPlayingBeforeInterruption = false

    // MARK: - Sleep Timer Properties

    /// Whether the sleep timer is active
    private(set) var isTimerActive = false

    /// Remaining seconds on the sleep timer
    private(set) var timerRemainingSeconds: Int = 0

    /// Total seconds for the current timer
    private(set) var timerTotalSeconds: Int = 0

    /// Timer instance for countdown
    private var sleepTimer: Timer?

    /// Original volume before fade-out begins
    private var originalVolume: Float = 1.0

    /// Whether we're in the fade-out phase
    private var isFadingOut = false

    /// Formatted remaining time string (MM:SS)
    var timerRemainingFormatted: String {
        let minutes = timerRemainingSeconds / 60
        let seconds = timerRemainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Initialization

    override init() {
        super.init()
        setupInterruptionHandling()
        setupRemoteCommandCenter()
    }

    // MARK: - Progress Service Injection

    func setProgressService(_ service: StoryProgressService) {
        self.progressService = service
    }

    // MARK: - Audio Session Configuration

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            // Use .playback category for background audio and lock screen controls
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            print("SleepContentPlayerService: Audio session configuration error: \(error.localizedDescription)")
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
                wasPlayingBeforeInterruption = isPlaying
                if wasPlayingBeforeInterruption {
                    pause()
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
                        resume()
                    } catch {
                        print("SleepContentPlayerService: Failed to reactivate audio session: \(error.localizedDescription)")
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

        // Play command
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            Task { @MainActor in
                self.resume()
            }
            return .success
        }

        // Pause command
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            Task { @MainActor in
                self.pause()
            }
            return .success
        }

        // Toggle play/pause command
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            Task { @MainActor in
                if self.isPlaying {
                    self.pause()
                } else {
                    self.resume()
                }
            }
            return .success
        }

        // Skip forward command (15 seconds)
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [15]
        commandCenter.skipForwardCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            Task { @MainActor in
                self.skipForward()
            }
            return .success
        }

        // Skip backward command (15 seconds)
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            Task { @MainActor in
                self.skipBackward()
            }
            return .success
        }
    }

    // MARK: - Playback Controls

    /// Play the specified sleep content
    func play(content: SleepContent) {
        // Stop any existing playback
        stop()

        guard let audioFileName = content.audioFileName else {
            print("SleepContentPlayerService: Content has no audio file")
            return
        }

        // Remove .mp3 extension if present for bundle URL lookup
        let baseName = audioFileName.replacingOccurrences(of: ".mp3", with: "")

        guard let url = Bundle.main.url(forResource: baseName, withExtension: "mp3") else {
            print("SleepContentPlayerService: Audio file not found: \(audioFileName)")
            return
        }

        do {
            configureAudioSession()

            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.numberOfLoops = 0  // Single playback, no looping
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()

            // Restore previous progress if available
            if let savedProgress = progressService?.getProgress(for: content.id), savedProgress > 0 {
                audioPlayer.currentTime = savedProgress
            }

            audioPlayer.play()

            player = audioPlayer
            currentContent = content
            isPlaying = true
            duration = audioPlayer.duration
            currentTime = audioPlayer.currentTime

            // Start progress tracking
            startProgressTracking()

            // Update Now Playing info
            updateNowPlayingInfo()
        } catch {
            print("SleepContentPlayerService: Error creating audio player: \(error.localizedDescription)")
        }
    }

    /// Pause playback
    func pause() {
        guard let player, isPlaying else { return }

        player.pause()
        isPlaying = false
        currentTime = player.currentTime

        // Save progress
        saveProgress()

        // Update Now Playing info
        updateNowPlayingInfo()
    }

    /// Resume playback
    func resume() {
        guard let player, !isPlaying else { return }

        do {
            try AVAudioSession.sharedInstance().setActive(true)
            player.play()
            isPlaying = true
            updateNowPlayingInfo()
        } catch {
            print("SleepContentPlayerService: Failed to resume: \(error.localizedDescription)")
        }
    }

    /// Stop playback completely
    func stop() {
        saveProgress()

        player?.stop()
        player = nil
        progressTimer?.invalidate()
        progressTimer = nil

        currentContent = nil
        isPlaying = false
        currentTime = 0
        duration = 0

        clearNowPlayingInfo()
    }

    /// Seek to specific time
    func seek(to time: TimeInterval) {
        guard let player else { return }

        let clampedTime = max(0, min(time, duration))
        player.currentTime = clampedTime
        currentTime = clampedTime

        // Save progress
        saveProgress()

        // Update Now Playing info
        updateNowPlayingInfo()
    }

    /// Skip forward by specified seconds (default 15)
    func skipForward(seconds: TimeInterval = 15) {
        seek(to: currentTime + seconds)
    }

    /// Skip backward by specified seconds (default 15)
    func skipBackward(seconds: TimeInterval = 15) {
        seek(to: currentTime - seconds)
    }

    // MARK: - Progress Tracking

    private func startProgressTracking() {
        progressTimer?.invalidate()

        // Update progress every 0.5 seconds for smooth UI updates
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateProgress()
            }
        }
    }

    private func updateProgress() {
        guard let player, isPlaying else { return }

        currentTime = player.currentTime

        // Periodically save progress (every 5 seconds)
        let secondsInt = Int(currentTime)
        if secondsInt % 5 == 0 {
            saveProgress()
        }
    }

    private func saveProgress() {
        guard let content = currentContent, currentTime > 0 else { return }
        progressService?.setProgress(currentTime, for: content.id)
    }

    // MARK: - Now Playing Info Center

    private func updateNowPlayingInfo() {
        guard let content = currentContent else {
            clearNowPlayingInfo()
            return
        }

        var nowPlayingInfo = [String: Any]()

        // Title
        nowPlayingInfo[MPMediaItemPropertyTitle] = content.title

        // Artist (narrator)
        nowPlayingInfo[MPMediaItemPropertyArtist] = content.narrator

        // Duration and elapsed time
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime

        // Playback rate (1.0 = playing, 0.0 = paused)
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0

        // Artwork - use placeholder
        if let image = UIImage(named: "NowPlayingArtwork") ?? UIImage(systemName: "moon.zzz.fill") {
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    private func clearNowPlayingInfo() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    // MARK: - Sleep Timer Controls

    /// Start the sleep timer with specified minutes
    func startSleepTimer(minutes: Int) {
        cancelSleepTimer()

        timerTotalSeconds = minutes * 60
        timerRemainingSeconds = timerTotalSeconds
        isTimerActive = true
        isFadingOut = false

        // Store original volume
        originalVolume = player?.volume ?? 1.0

        sleepTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.timerTick()
            }
        }
    }

    /// Cancel the sleep timer
    func cancelSleepTimer() {
        sleepTimer?.invalidate()
        sleepTimer = nil
        isTimerActive = false
        timerRemainingSeconds = 0
        timerTotalSeconds = 0
        isFadingOut = false

        // Restore original volume if we were fading
        player?.volume = originalVolume
    }

    /// Internal timer tick handler
    private func timerTick() {
        guard timerRemainingSeconds > 0 else { return }

        timerRemainingSeconds -= 1

        // Start 30-second fade-out when timer is about to end
        let fadeOutDuration: Int = 30
        if timerRemainingSeconds <= fadeOutDuration && timerRemainingSeconds > 0 {
            isFadingOut = true
            let fadeProgress = Float(timerRemainingSeconds) / Float(fadeOutDuration)
            player?.volume = originalVolume * fadeProgress
        }

        // Timer complete - stop playback
        if timerRemainingSeconds <= 0 {
            completeTimer()
        }
    }

    /// Handle timer completion
    private func completeTimer() {
        // Save progress before stopping
        saveProgress()

        // Stop playback
        player?.stop()

        // Reset timer state
        sleepTimer?.invalidate()
        sleepTimer = nil
        isTimerActive = false
        timerTotalSeconds = 0
        isFadingOut = false

        // Reset player state
        isPlaying = false
        progressTimer?.invalidate()
        progressTimer = nil

        // Restore volume for next playback
        player?.volume = originalVolume

        // Update UI
        updateNowPlayingInfo()
    }
}

// MARK: - AVAudioPlayerDelegate

extension SleepContentPlayerService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            // Content finished playing
            if flag {
                // Clear progress since content was completed
                if let contentId = currentContent?.id {
                    progressService?.clearProgress(for: contentId)
                }
            }

            // Reset state
            self.isPlaying = false
            self.currentTime = self.duration
            self.progressTimer?.invalidate()
            self.progressTimer = nil

            // Update Now Playing info to show completion
            self.updateNowPlayingInfo()
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            print("SleepContentPlayerService: Decode error: \(error?.localizedDescription ?? "Unknown error")")
            self.stop()
        }
    }
}
