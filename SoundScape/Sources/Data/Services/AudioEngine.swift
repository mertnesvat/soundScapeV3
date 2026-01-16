import AVFoundation
import Foundation

@Observable
@MainActor
final class AudioEngine: AudioPlayerProtocol {
    // MARK: - Properties

    private var players: [String: AVAudioPlayer] = [:]
    private(set) var activeSounds: [ActiveSound] = []

    var isAnyPlaying: Bool {
        activeSounds.contains { $0.isPlaying }
    }

    // MARK: - Initialization

    init() {
        configureAudioSession()
    }

    // MARK: - Audio Session Configuration

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Audio session configuration error: \(error.localizedDescription)")
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
    }

    func stop(soundId: String) {
        guard let player = players[soundId] else { return }

        // Fade out before stopping
        fadeOut(player: player, duration: 0.3) { [weak self] in
            player.stop()
            self?.players.removeValue(forKey: soundId)
            self?.activeSounds.removeAll { $0.id == soundId }
        }
    }

    func stopAll() {
        for soundId in players.keys {
            stop(soundId: soundId)
        }
    }

    func pauseAll() {
        for activeSound in activeSounds where activeSound.isPlaying {
            pause(soundId: activeSound.id)
        }
    }

    func resumeAll() {
        for activeSound in activeSounds where !activeSound.isPlaying {
            resume(soundId: activeSound.id)
        }
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
