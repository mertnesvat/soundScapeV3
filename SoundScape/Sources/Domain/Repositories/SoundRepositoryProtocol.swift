import Foundation

protocol SoundRepositoryProtocol {
    func getAllSounds() -> [Sound]
    func getSounds(byCategory category: SoundCategory) -> [Sound]
    func getSound(byId id: String) -> Sound?
}
