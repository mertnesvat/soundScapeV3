import Foundation

@Observable
final class SavedMixesService {
    private(set) var mixes: [SavedMix] = []
    private let fileURL: URL

    init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = documentsPath.appendingPathComponent("saved_mixes.json")
        loadMixes()
    }

    func saveMix(name: String, sounds: [ActiveSound]) {
        let mixSounds = sounds.map { SavedMix.MixSound(soundId: $0.id, volume: $0.volume) }
        let mix = SavedMix(id: UUID(), name: name, sounds: mixSounds, createdAt: Date())
        mixes.insert(mix, at: 0)
        persistMixes()
    }

    func deleteMix(_ mix: SavedMix) {
        mixes.removeAll { $0.id == mix.id }
        persistMixes()
    }

    func renameMix(_ mix: SavedMix, to newName: String) {
        if let index = mixes.firstIndex(where: { $0.id == mix.id }) {
            mixes[index].name = newName
            persistMixes()
        }
    }

    private func loadMixes() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            mixes = try JSONDecoder().decode([SavedMix].self, from: data)
        } catch {
            print("Error loading mixes: \(error)")
        }
    }

    private func persistMixes() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(mixes)
            try data.write(to: fileURL)
        } catch {
            print("Error saving mixes: \(error)")
        }
    }
}
