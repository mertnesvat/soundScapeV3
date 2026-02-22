import XCTest
@testable import SoundScape

final class SleepContentTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeContent(
        id: String = "test_content",
        duration: TimeInterval = 600,
        audioFileName: String? = "test.mp3",
        coverImageName: String? = nil
    ) -> SleepContent {
        return SleepContent(
            id: id,
            title: "Test Content",
            narrator: "Test Narrator",
            duration: duration,
            contentType: .yogaNidra,
            description: "Test description",
            audioFileName: audioFileName,
            coverImageName: coverImageName
        )
    }

    // MARK: - isAvailable Tests

    func test_isAvailable_withAudioFile_returnsTrue() {
        let content = makeContent(audioFileName: "test.mp3")

        XCTAssertTrue(content.isAvailable)
    }

    func test_isAvailable_withNilAudioFile_returnsFalse() {
        let content = makeContent(audioFileName: nil)

        XCTAssertFalse(content.isAvailable)
    }

    // MARK: - hasCoverImage Tests

    func test_hasCoverImage_withCoverImage_returnsTrue() {
        let content = makeContent(coverImageName: "cover.png")

        XCTAssertTrue(content.hasCoverImage)
    }

    func test_hasCoverImage_withNilCoverImage_returnsFalse() {
        let content = makeContent(coverImageName: nil)

        XCTAssertFalse(content.hasCoverImage)
    }

    // MARK: - formattedDuration Tests

    func test_formattedDuration_fiveMinutes() {
        let content = makeContent(duration: 300) // 5 minutes
        XCTAssertEqual(content.formattedDuration, "5 min")
    }

    func test_formattedDuration_tenMinutes() {
        let content = makeContent(duration: 600) // 10 minutes
        XCTAssertEqual(content.formattedDuration, "10 min")
    }

    func test_formattedDuration_thirtyMinutes() {
        let content = makeContent(duration: 1800) // 30 minutes
        XCTAssertEqual(content.formattedDuration, "30 min")
    }

    func test_formattedDuration_exactlyOneHour() {
        let content = makeContent(duration: 3600) // 60 minutes
        XCTAssertEqual(content.formattedDuration, "1h")
    }

    func test_formattedDuration_oneAndHalfHours() {
        let content = makeContent(duration: 5400) // 90 minutes
        XCTAssertEqual(content.formattedDuration, "1h 30m")
    }

    func test_formattedDuration_twoHours() {
        let content = makeContent(duration: 7200) // 120 minutes
        XCTAssertEqual(content.formattedDuration, "2h")
    }

    func test_formattedDuration_zeroDuration() {
        let content = makeContent(duration: 0)
        XCTAssertEqual(content.formattedDuration, "0 min")
    }

    func test_formattedDuration_lessThanOneMinute() {
        let content = makeContent(duration: 45) // 45 seconds
        XCTAssertEqual(content.formattedDuration, "0 min")
    }

    // MARK: - compactDuration Tests

    func test_compactDuration_fiveMinutes() {
        let content = makeContent(duration: 300)
        XCTAssertEqual(content.compactDuration, "5m")
    }

    func test_compactDuration_thirtyMinutes() {
        let content = makeContent(duration: 1800)
        XCTAssertEqual(content.compactDuration, "30m")
    }

    func test_compactDuration_exactlyOneHour() {
        let content = makeContent(duration: 3600)
        XCTAssertEqual(content.compactDuration, "1h")
    }

    func test_compactDuration_oneAndHalfHours() {
        let content = makeContent(duration: 5400)
        XCTAssertEqual(content.compactDuration, "1.5h")
    }

    func test_compactDuration_twoHours() {
        let content = makeContent(duration: 7200)
        XCTAssertEqual(content.compactDuration, "2h")
    }

    // MARK: - Equatable Tests

    func test_equatable_sameProperties_areEqual() {
        let content1 = SleepContent(
            id: "test", title: "Title", narrator: "Narrator",
            duration: 600, contentType: .yogaNidra, description: "Desc",
            audioFileName: "test.mp3", coverImageName: nil
        )
        let content2 = SleepContent(
            id: "test", title: "Title", narrator: "Narrator",
            duration: 600, contentType: .yogaNidra, description: "Desc",
            audioFileName: "test.mp3", coverImageName: nil
        )

        XCTAssertEqual(content1, content2)
    }

    func test_equatable_differentIds_areNotEqual() {
        let content1 = makeContent(id: "content_1")
        let content2 = makeContent(id: "content_2")

        XCTAssertNotEqual(content1, content2)
    }

    // MARK: - SleepContentType Tests

    func test_allContentTypes_haveNonEmptyLocalizedNames() {
        for type in SleepContentType.allCases {
            XCTAssertFalse(type.localizedName.isEmpty, "\(type.rawValue) should have a localized name")
        }
    }

    func test_allContentTypes_haveIcons() {
        for type in SleepContentType.allCases {
            XCTAssertFalse(type.icon.isEmpty, "\(type.rawValue) should have an icon")
        }
    }

    func test_allContentTypes_haveTaglines() {
        for type in SleepContentType.allCases {
            XCTAssertFalse(type.tagline.isEmpty, "\(type.rawValue) should have a tagline")
        }
    }

    func test_allContentTypes_haveLocalizedTaglines() {
        for type in SleepContentType.allCases {
            XCTAssertFalse(type.localizedTagline.isEmpty, "\(type.rawValue) should have a localized tagline")
        }
    }

    func test_contentType_idEqualsRawValue() {
        for type in SleepContentType.allCases {
            XCTAssertEqual(type.id, type.rawValue)
        }
    }

    func test_contentType_sortOrderIsUnique() {
        let orders = SleepContentType.allCases.map { $0.sortOrder }
        let uniqueOrders = Set(orders)

        XCTAssertEqual(orders.count, uniqueOrders.count, "Sort orders should be unique")
    }

    func test_contentType_sortOrderIsSequential() {
        let orders = SleepContentType.allCases.map { $0.sortOrder }.sorted()

        for i in 0..<orders.count {
            XCTAssertEqual(orders[i], i, "Sort order should be sequential starting from 0")
        }
    }

    func test_contentType_count() {
        XCTAssertEqual(SleepContentType.allCases.count, 6)
    }

    // MARK: - Specific Content Type Tests

    func test_yogaNidra_hasCorrectProperties() {
        let type = SleepContentType.yogaNidra

        XCTAssertEqual(type.rawValue, "Yoga Nidra")
        XCTAssertEqual(type.icon, "figure.mind.and.body")
        XCTAssertEqual(type.sortOrder, 0)
    }

    func test_sleepStory_hasCorrectProperties() {
        let type = SleepContentType.sleepStory

        XCTAssertEqual(type.rawValue, "Sleep Stories")
        XCTAssertEqual(type.icon, "book.closed.fill")
        XCTAssertEqual(type.sortOrder, 1)
    }

    func test_breathingExercise_hasCorrectProperties() {
        let type = SleepContentType.breathingExercise

        XCTAssertEqual(type.rawValue, "Breathing")
        XCTAssertEqual(type.icon, "wind")
        XCTAssertEqual(type.sortOrder, 3)
    }
}
