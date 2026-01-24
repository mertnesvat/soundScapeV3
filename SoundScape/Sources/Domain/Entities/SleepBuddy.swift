import Foundation

/// Represents a paired sleep buddy for accountability
struct SleepBuddy: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var currentStreak: Int
    var lastActiveDate: Date
    var isPaused: Bool

    init(
        id: UUID = UUID(),
        name: String,
        currentStreak: Int = 0,
        lastActiveDate: Date = Date(),
        isPaused: Bool = false
    ) {
        self.id = id
        self.name = name
        self.currentStreak = currentStreak
        self.lastActiveDate = lastActiveDate
        self.isPaused = isPaused
    }
}

/// Represents the local user's buddy profile for sharing
struct BuddyProfile: Codable {
    let id: UUID
    var name: String
    var currentStreak: Int
    var lastActiveDate: Date
    var isPaused: Bool

    init(
        id: UUID = UUID(),
        name: String,
        currentStreak: Int = 0,
        lastActiveDate: Date = Date(),
        isPaused: Bool = false
    ) {
        self.id = id
        self.name = name
        self.currentStreak = currentStreak
        self.lastActiveDate = lastActiveDate
        self.isPaused = isPaused
    }
}

/// Invite code for pairing
struct BuddyInvite: Codable {
    let code: String
    let createdAt: Date
    let expiresAt: Date
    let creatorId: UUID
    let creatorName: String

    var isExpired: Bool {
        Date() > expiresAt
    }
}
