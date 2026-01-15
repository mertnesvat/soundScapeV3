import Foundation

final class SoundRepository: SoundRepositoryProtocol {
    private let dataSource: LocalSoundDataSource

    init(dataSource: LocalSoundDataSource = .shared) {
        self.dataSource = dataSource
    }

    func getAllSounds() -> [Sound] {
        return dataSource.getAllSounds()
    }

    func getSounds(byCategory category: SoundCategory) -> [Sound] {
        return dataSource.getAllSounds().filter { $0.category == category }
    }

    func getSound(byId id: String) -> Sound? {
        return dataSource.getAllSounds().first { $0.id == id }
    }
}
