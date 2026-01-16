import Foundation
import SwiftUI

@Observable
final class StoryProgressService {
    private let progressKey = "story_progress"
    private(set) var progress: [String: TimeInterval] = [:]  // storyId: seconds played

    init() {
        loadProgress()
    }

    func getProgress(for storyId: String) -> TimeInterval {
        progress[storyId] ?? 0
    }

    func setProgress(_ seconds: TimeInterval, for storyId: String) {
        progress[storyId] = seconds
        saveProgress()
    }

    func clearProgress(for storyId: String) {
        progress.removeValue(forKey: storyId)
        saveProgress()
    }

    func clearAllProgress() {
        progress.removeAll()
        saveProgress()
    }

    var inProgressStoryIds: [String] {
        progress.filter { $0.value > 0 }.map { $0.key }
    }

    func progressFraction(for story: Story) -> Double {
        let played = getProgress(for: story.id)
        guard story.duration > 0 else { return 0 }
        return min(played / story.duration, 1.0)
    }

    func remainingTime(for story: Story) -> TimeInterval {
        let played = getProgress(for: story.id)
        return max(story.duration - played, 0)
    }

    func isCompleted(_ story: Story) -> Bool {
        progressFraction(for: story) >= 0.95
    }

    // MARK: - Persistence

    private func loadProgress() {
        guard let data = UserDefaults.standard.data(forKey: progressKey),
              let decoded = try? JSONDecoder().decode([String: TimeInterval].self, from: data) else {
            progress = [:]
            return
        }
        progress = decoded
    }

    private func saveProgress() {
        guard let data = try? JSONEncoder().encode(progress) else { return }
        UserDefaults.standard.set(data, forKey: progressKey)
    }
}
