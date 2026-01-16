import Foundation

@MainActor
protocol AudioPlayerProtocol: AnyObject {
    var activeSounds: [ActiveSound] { get }
    var isAnyPlaying: Bool { get }

    func play(sound: Sound)
    func pause(soundId: String)
    func resume(soundId: String)
    func stop(soundId: String)
    func stopAll()
    func pauseAll()
    func resumeAll()
    func setVolume(_ volume: Float, for soundId: String)
    func isPlaying(soundId: String) -> Bool
}
