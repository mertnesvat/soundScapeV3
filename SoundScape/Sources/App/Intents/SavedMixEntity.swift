import AppIntents

/// Entity representing a saved mix for use in App Intents
struct SavedMixEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Saved Mix"

    static var defaultQuery = SavedMixQuery()

    var id: String
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }

    init(from mix: SavedMix) {
        self.id = mix.id.uuidString
        self.name = mix.name
    }
}

/// Query for finding saved mixes by name
struct SavedMixQuery: EntityQuery {
    @MainActor
    func entities(for identifiers: [String]) async throws -> [SavedMixEntity] {
        let container = ServiceContainer.shared
        return container.savedMixesService.mixes
            .filter { identifiers.contains($0.id.uuidString) }
            .map { SavedMixEntity(from: $0) }
    }

    @MainActor
    func suggestedEntities() async throws -> [SavedMixEntity] {
        let container = ServiceContainer.shared
        return container.savedMixesService.mixes.map { SavedMixEntity(from: $0) }
    }
}

extension SavedMixQuery: EntityStringQuery {
    @MainActor
    func entities(matching string: String) async throws -> [SavedMixEntity] {
        let container = ServiceContainer.shared
        let lowercasedString = string.lowercased()

        return container.savedMixesService.mixes
            .filter { $0.name.lowercased().contains(lowercasedString) }
            .map { SavedMixEntity(from: $0) }
    }
}
