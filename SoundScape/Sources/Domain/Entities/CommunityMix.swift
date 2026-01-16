import Foundation

struct CommunityMix: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let name: String
    let creatorName: String
    let sounds: [SavedMix.MixSound]
    let playCount: Int
    let upvotes: Int
    let tags: [String]
    let category: CommunityCategory
    let createdAt: Date
    let isFeatured: Bool

    var soundCount: Int {
        sounds.count
    }
}

enum CommunityCategory: String, CaseIterable, Codable {
    case trending = "Trending"
    case popular = "Popular"
    case sleep = "Sleep"
    case focus = "Focus"
    case nature = "Nature"

    var icon: String {
        switch self {
        case .trending: return "flame.fill"
        case .popular: return "star.fill"
        case .sleep: return "moon.zzz.fill"
        case .focus: return "brain.head.profile"
        case .nature: return "leaf.fill"
        }
    }
}
