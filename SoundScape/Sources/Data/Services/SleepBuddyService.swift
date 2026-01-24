import Foundation

/// Service for managing sleep buddy accountability pairing
@Observable
final class SleepBuddyService {
    // MARK: - Keys
    private let buddyKey = "sleep_buddy"
    private let profileKey = "buddy_profile"
    private let inviteKey = "buddy_invite"
    private let pairedKey = "is_buddy_paired"

    // MARK: - Published State
    private(set) var buddy: SleepBuddy?
    private(set) var myProfile: BuddyProfile
    private(set) var pendingInvite: BuddyInvite?

    var isPaired: Bool {
        buddy != nil
    }

    var myStreak: Int {
        myProfile.currentStreak
    }

    var isSharingPaused: Bool {
        myProfile.isPaused
    }

    // MARK: - Dependencies
    private weak var insightsService: InsightsService?

    // MARK: - Initialization

    init() {
        // Load profile or create default
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let profile = try? JSONDecoder().decode(BuddyProfile.self, from: data) {
            self.myProfile = profile
        } else {
            self.myProfile = BuddyProfile(
                name: "Me",
                currentStreak: 0
            )
        }

        loadBuddy()
        loadPendingInvite()
    }

    func setInsightsService(_ service: InsightsService) {
        self.insightsService = service
        updateMyStreak()
    }

    // MARK: - Streak Calculation

    func updateMyStreak() {
        guard let insightsService = insightsService else { return }

        let streak = calculateStreak(from: insightsService.sessions)
        myProfile = BuddyProfile(
            id: myProfile.id,
            name: myProfile.name,
            currentStreak: streak,
            lastActiveDate: insightsService.sessions.first?.date ?? Date(),
            isPaused: myProfile.isPaused
        )
        saveProfile()
    }

    private func calculateStreak(from sessions: [SleepSession]) -> Int {
        guard !sessions.isEmpty else { return 0 }

        let calendar = Calendar.current
        let sortedSessions = sessions.sorted { $0.date > $1.date }

        var streak = 0
        var lastDate = calendar.startOfDay(for: Date())

        // Check if there's a session today or yesterday to start the streak
        guard let firstSession = sortedSessions.first else { return 0 }
        let firstSessionDay = calendar.startOfDay(for: firstSession.date)

        // Allow for today or yesterday to count
        let daysDifference = calendar.dateComponents([.day], from: firstSessionDay, to: lastDate).day ?? 0
        if daysDifference > 1 {
            return 0 // Streak broken
        }

        // Count consecutive days
        var processedDays: Set<Date> = []

        for session in sortedSessions {
            let sessionDay = calendar.startOfDay(for: session.date)

            // Skip if we already counted this day
            if processedDays.contains(sessionDay) {
                continue
            }

            let daysBetween = calendar.dateComponents([.day], from: sessionDay, to: lastDate).day ?? 0

            if daysBetween <= 1 {
                streak += 1
                processedDays.insert(sessionDay)
                lastDate = sessionDay
            } else {
                break // Streak broken
            }
        }

        return streak
    }

    // MARK: - Invite Management

    func generateInviteCode() -> String {
        let code = String(format: "%06d", Int.random(in: 100000...999999))

        let invite = BuddyInvite(
            code: code,
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(24 * 60 * 60), // 24 hours
            creatorId: myProfile.id,
            creatorName: myProfile.name
        )

        pendingInvite = invite
        saveInvite(invite)

        return code
    }

    func acceptInvite(code: String) -> Bool {
        // In a real implementation, this would validate against CloudKit
        // For now, we simulate acceptance with mock buddy data

        // Simulate network delay behavior
        guard code.count == 6, Int(code) != nil else {
            return false
        }

        // Create mock buddy based on code (for testing)
        let mockBuddy = SleepBuddy(
            name: generateMockBuddyName(from: code),
            currentStreak: Int.random(in: 3...14),
            lastActiveDate: Date().addingTimeInterval(-Double.random(in: 0...7200)),
            isPaused: false
        )

        buddy = mockBuddy
        saveBuddy()
        pendingInvite = nil
        clearSavedInvite()

        return true
    }

    private func generateMockBuddyName(from code: String) -> String {
        let names = ["Alex", "Jordan", "Sam", "Taylor", "Morgan", "Casey", "Riley", "Quinn"]
        let index = (Int(code) ?? 0) % names.count
        return names[index]
    }

    // MARK: - Pairing Controls

    func unpair() {
        buddy = nil
        clearSavedBuddy()
    }

    func pauseSharing() {
        myProfile = BuddyProfile(
            id: myProfile.id,
            name: myProfile.name,
            currentStreak: myProfile.currentStreak,
            lastActiveDate: myProfile.lastActiveDate,
            isPaused: true
        )
        saveProfile()
    }

    func resumeSharing() {
        myProfile = BuddyProfile(
            id: myProfile.id,
            name: myProfile.name,
            currentStreak: myProfile.currentStreak,
            lastActiveDate: myProfile.lastActiveDate,
            isPaused: false
        )
        saveProfile()
    }

    func updateMyName(_ name: String) {
        myProfile = BuddyProfile(
            id: myProfile.id,
            name: name,
            currentStreak: myProfile.currentStreak,
            lastActiveDate: myProfile.lastActiveDate,
            isPaused: myProfile.isPaused
        )
        saveProfile()
    }

    // MARK: - Mock Data for Testing

    func loadMockBuddy() {
        buddy = SleepBuddy(
            name: "Sarah",
            currentStreak: 7,
            lastActiveDate: Date().addingTimeInterval(-3600), // 1 hour ago
            isPaused: false
        )
        saveBuddy()
    }

    // MARK: - Persistence

    private func loadBuddy() {
        guard let data = UserDefaults.standard.data(forKey: buddyKey) else { return }
        buddy = try? JSONDecoder().decode(SleepBuddy.self, from: data)
    }

    private func saveBuddy() {
        guard let buddy = buddy else { return }
        if let data = try? JSONEncoder().encode(buddy) {
            UserDefaults.standard.set(data, forKey: buddyKey)
        }
    }

    private func clearSavedBuddy() {
        UserDefaults.standard.removeObject(forKey: buddyKey)
    }

    private func saveProfile() {
        if let data = try? JSONEncoder().encode(myProfile) {
            UserDefaults.standard.set(data, forKey: profileKey)
        }
    }

    private func loadPendingInvite() {
        guard let data = UserDefaults.standard.data(forKey: inviteKey) else { return }
        let invite = try? JSONDecoder().decode(BuddyInvite.self, from: data)

        // Only load if not expired
        if let invite = invite, !invite.isExpired {
            pendingInvite = invite
        } else {
            clearSavedInvite()
        }
    }

    private func saveInvite(_ invite: BuddyInvite) {
        if let data = try? JSONEncoder().encode(invite) {
            UserDefaults.standard.set(data, forKey: inviteKey)
        }
    }

    private func clearSavedInvite() {
        UserDefaults.standard.removeObject(forKey: inviteKey)
    }

    // MARK: - CloudKit Integration (Stubs)

    /*
    // TODO: Implement CloudKit integration when Apple Developer account is configured

    import CloudKit

    private let container = CKContainer(identifier: "iCloud.com.StudioNext.SoundScape")
    private let database: CKDatabase { container.publicCloudDatabase }

    func syncProfileToCloudKit() async throws {
        let record = CKRecord(recordType: "BuddyProfile")
        record["name"] = myProfile.name
        record["currentStreak"] = myProfile.currentStreak
        record["lastActiveDate"] = myProfile.lastActiveDate
        record["isPaused"] = myProfile.isPaused

        try await database.save(record)
    }

    func fetchBuddyFromCloudKit(buddyId: UUID) async throws -> SleepBuddy? {
        let predicate = NSPredicate(format: "id == %@", buddyId.uuidString)
        let query = CKQuery(recordType: "BuddyProfile", predicate: predicate)

        let (matchResults, _) = try await database.records(matching: query)

        guard let (_, result) = matchResults.first,
              let record = try? result.get() else {
            return nil
        }

        return SleepBuddy(
            id: buddyId,
            name: record["name"] as? String ?? "Unknown",
            currentStreak: record["currentStreak"] as? Int ?? 0,
            lastActiveDate: record["lastActiveDate"] as? Date ?? Date(),
            isPaused: record["isPaused"] as? Bool ?? false
        )
    }

    func validateInviteCode(_ code: String) async throws -> BuddyInvite? {
        let predicate = NSPredicate(format: "code == %@ AND expiresAt > %@", code, Date() as NSDate)
        let query = CKQuery(recordType: "BuddyInvite", predicate: predicate)

        let (matchResults, _) = try await database.records(matching: query)

        guard let (_, result) = matchResults.first,
              let record = try? result.get() else {
            return nil
        }

        return BuddyInvite(
            code: record["code"] as? String ?? "",
            createdAt: record["createdAt"] as? Date ?? Date(),
            expiresAt: record["expiresAt"] as? Date ?? Date(),
            creatorId: UUID(uuidString: record["creatorId"] as? String ?? "") ?? UUID(),
            creatorName: record["creatorName"] as? String ?? "Unknown"
        )
    }
    */
}
