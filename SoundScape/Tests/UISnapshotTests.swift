import XCTest
import SwiftUI
@testable import SoundScape

/// Lightweight structural "snapshot" tests for the simple-UI redesign.
///
/// These tests intentionally avoid hosting views in a UIHostingController so
/// the suite stays under 1s and doesn't hang the verifier. They use Mirror
/// reflection to assert that each redesigned view still declares its expected
/// property wrappers, and (where the body has no environment dependencies)
/// inspect the rendered body description for forbidden tokens.
///
/// The intent is to catch regressions of the new simple-UI invariants:
///   * exactly three primary tabs
///   * one card style (no LinearGradient on SoundCardView)
///   * the redesigned views still expose the same shape they had after the
///     redesign — adding/removing observed services or @State is a structural
///     break that should fail this suite.
final class UISnapshotTests: XCTestCase {

    // MARK: - ContentView Tab Count Regression

    func test_contentView_exposesExactlyThreeTabs() {
        XCTAssertEqual(
            ContentView.Tab.allCases.count,
            3,
            "ContentView must expose exactly 3 tabs (sounds, windDown, insights) after the simple-UI redesign"
        )
    }

    func test_contentView_tabs_areTheSimpleUITrio() {
        let raw = ContentView.Tab.allCases.map { $0.rawValue }
        XCTAssertEqual(Set(raw), Set(["sounds", "windDown", "insights"]),
                       "ContentView tabs should be the redesigned trio")
    }

    // MARK: - SoundCardView Body Regression (no gradient invariant)

    func test_soundCardView_bodyDescription_containsNoLinearGradient() {
        let card = makeSoundCardView()
        let bodyDescription = String(describing: card.body)
        XCTAssertFalse(
            bodyDescription.contains("LinearGradient"),
            "SoundCardView body must not contain LinearGradient — simple-UI invariant is one flat card style"
        )
    }

    func test_soundCardView_body_isNonEmpty() {
        let card = makeSoundCardView()
        let bodyDescription = String(describing: card.body)
        XCTAssertFalse(bodyDescription.isEmpty,
                       "SoundCardView body description should be non-empty")
        XCTAssertTrue(bodyDescription.contains("Button") || bodyDescription.contains("button"),
                      "SoundCardView body should still be tap-driven (Button-rooted)")
    }

    // MARK: - SoundCardView Structural Snapshot

    func test_soundCardView_declaresExpectedStoredProperties() {
        let card = makeSoundCardView()
        let labels = Set(Mirror(reflecting: card).children.compactMap { $0.label })
        for required in ["sound", "isPlaying", "isFavorite", "isLocked",
                         "onTogglePlay", "onToggleFavorite", "onLockedTap", "_heartScale"] {
            XCTAssertTrue(labels.contains(required),
                          "SoundCardView should declare \(required) (current labels: \(labels))")
        }
    }

    // MARK: - SoundsView Structural Snapshot

    func test_soundsView_declaresExpectedEnvironmentAndState() {
        let view = SoundsView()
        let labels = Set(Mirror(reflecting: view).children.compactMap { $0.label })
        // Every redesigned view should keep at least its core wired services.
        for required in ["_audioEngine", "_favoritesService", "_appearanceService",
                         "_premiumManager", "_paywallService", "_analyticsService",
                         "_viewModel", "_showMixerSheet", "_showTimerSheet", "_showSavedSheet"] {
            XCTAssertTrue(labels.contains(required),
                          "SoundsView should declare \(required) (current labels: \(labels))")
        }
    }

    // MARK: - NowPlayingBarView Structural Snapshot

    func test_nowPlayingBarView_declaresExpectedProperties() {
        var showMixer = false
        let binding = Binding(get: { showMixer }, set: { showMixer = $0 })
        let view = NowPlayingBarView(showMixer: binding)
        let labels = Set(Mirror(reflecting: view).children.compactMap { $0.label })
        XCTAssertTrue(labels.contains("_audioEngine"),
                      "NowPlayingBarView should observe AudioEngine (labels: \(labels))")
        XCTAssertTrue(labels.contains("_showMixer"),
                      "NowPlayingBarView should bind showMixer (labels: \(labels))")
    }

    // MARK: - MixerView Structural Snapshot

    func test_mixerView_declaresExpectedEnvironmentAndState() {
        let view = MixerView()
        let labels = Set(Mirror(reflecting: view).children.compactMap { $0.label })
        for required in ["_audioEngine", "_mixesService", "_analyticsService",
                         "_dismiss", "_showSaveMixSheet"] {
            XCTAssertTrue(labels.contains(required),
                          "MixerView should declare \(required) (current labels: \(labels))")
        }
    }

    // MARK: - SleepTimerView Structural Snapshot

    func test_sleepTimerView_declaresExpectedEnvironmentAndState() {
        let view = SleepTimerView()
        let labels = Set(Mirror(reflecting: view).children.compactMap { $0.label })
        for required in ["_timerService", "_dismiss", "_selectedMinutes"] {
            XCTAssertTrue(labels.contains(required),
                          "SleepTimerView should declare \(required) (current labels: \(labels))")
        }
    }

    // MARK: - SavedMixesView Structural Snapshot

    func test_savedMixesView_declaresExpectedEnvironment() {
        let view = SavedMixesView()
        let labels = Set(Mirror(reflecting: view).children.compactMap { $0.label })
        for required in ["_mixesService", "_audioEngine"] {
            XCTAssertTrue(labels.contains(required),
                          "SavedMixesView should declare \(required) (current labels: \(labels))")
        }
    }

    // MARK: - StoriesView Structural Snapshot

    func test_storiesView_declaresExpectedEnvironment() {
        let view = StoriesView()
        let labels = Set(Mirror(reflecting: view).children.compactMap { $0.label })
        XCTAssertTrue(labels.contains("_progressService"),
                      "StoriesView should observe StoryProgressService (labels: \(labels))")
        XCTAssertGreaterThanOrEqual(
            labels.count, 1,
            "StoriesView should declare at least one stored property"
        )
    }

    // MARK: - InsightsView Structural Snapshot

    func test_insightsView_declaresExpectedEnvironment() {
        let view = InsightsView()
        let labels = Set(Mirror(reflecting: view).children.compactMap { $0.label })
        for required in ["_insightsService", "_paywallService", "_premiumManager",
                         "_onboardingService", "_subscriptionService", "_analyticsService"] {
            XCTAssertTrue(labels.contains(required),
                          "InsightsView should declare \(required) (current labels: \(labels))")
        }
    }

    // MARK: - Helpers

    private func makeSoundCardView(isLocked: Bool = false) -> SoundCardView {
        SoundCardView(
            sound: Sound(
                id: "rain_storm",
                name: "Rain Storm",
                category: .weather,
                fileName: "rain_storm.mp3"
            ),
            isPlaying: false,
            isFavorite: false,
            isLocked: isLocked,
            onTogglePlay: {},
            onToggleFavorite: {},
            onLockedTap: {}
        )
    }
}
