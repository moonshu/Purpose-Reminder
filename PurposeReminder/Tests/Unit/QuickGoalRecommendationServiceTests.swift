import XCTest

final class QuickGoalRecommendationServiceTests: XCTestCase {
    private let service = QuickGoalRecommendationService()

    func testRecommend_OrdersByFourStepPriorityAndDeduplicates() {
        let now = Date()
        let appA = Data("app.a".utf8)
        let appB = Data("app.b".utf8)

        let favorite = makeTemplate(
            text: "favorite",
            targetAppTokenData: appA,
            isFavorite: true,
            useCount: 1,
            lastUsedAt: now.addingTimeInterval(-300)
        )

        let sameAppRecent = makeTemplate(
            text: "same-app-recent",
            targetAppTokenData: appA,
            isFavorite: false,
            useCount: 2,
            lastUsedAt: now.addingTimeInterval(-60)
        )

        let globalRecent = makeTemplate(
            text: "global-recent",
            targetAppTokenData: appB,
            isFavorite: false,
            useCount: 3,
            lastUsedAt: now.addingTimeInterval(-10)
        )

        let appDefault = makeTemplate(
            text: "app-default",
            targetAppTokenData: appA,
            isFavorite: false,
            useCount: 0,
            lastUsedAt: nil
        )

        let result = service.recommend(
            templates: [globalRecent, favorite, appDefault, sameAppRecent],
            targetAppTokenData: appA,
            defaultTemplateId: appDefault.id
        )

        XCTAssertEqual(
            result.recommendations.map(\.template.id),
            [favorite.id, sameAppRecent.id, globalRecent.id, appDefault.id]
        )

        XCTAssertEqual(
            result.recommendations.map(\.source),
            [.favorite, .recentForTargetApp, .recentGlobal, .appDefault]
        )
        XCTAssertTrue(result.shouldShowCustomGoalInput)
    }

    func testRecommend_DoesNotAppendDefaultTwiceWhenAlreadyRanked() {
        let now = Date()
        let appA = Data("app.a".utf8)

        let favoriteDefault = makeTemplate(
            text: "favorite-default",
            targetAppTokenData: appA,
            isFavorite: true,
            useCount: 9,
            lastUsedAt: now
        )

        let result = service.recommend(
            templates: [favoriteDefault],
            targetAppTokenData: appA,
            defaultTemplateId: favoriteDefault.id
        )

        XCTAssertEqual(result.recommendations.count, 1)
        XCTAssertEqual(result.recommendations.first?.template.id, favoriteDefault.id)
        XCTAssertEqual(result.recommendations.first?.source, .favorite)
    }

    func testRecommend_PrioritizesSameAppRecentOverNewerGlobalRecent() {
        let now = Date()
        let appA = Data("app.a".utf8)
        let appB = Data("app.b".utf8)

        let sameAppRecentOlder = makeTemplate(
            text: "same-app-recent-older",
            targetAppTokenData: appA,
            isFavorite: false,
            useCount: 1,
            lastUsedAt: now.addingTimeInterval(-3600)
        )

        let globalRecentNewer = makeTemplate(
            text: "global-recent-newer",
            targetAppTokenData: appB,
            isFavorite: false,
            useCount: 1,
            lastUsedAt: now.addingTimeInterval(-10)
        )

        let result = service.recommend(
            templates: [globalRecentNewer, sameAppRecentOlder],
            targetAppTokenData: appA,
            defaultTemplateId: nil
        )

        XCTAssertEqual(
            result.recommendations.map(\.template.id),
            [sameAppRecentOlder.id, globalRecentNewer.id]
        )
        XCTAssertEqual(
            result.recommendations.map(\.source),
            [.recentForTargetApp, .recentGlobal]
        )
        XCTAssertTrue(result.shouldShowCustomGoalInput)
    }

    private func makeTemplate(
        text: String,
        targetAppTokenData: Data?,
        isFavorite: Bool,
        useCount: Int,
        lastUsedAt: Date?
    ) -> GoalTemplate {
        GoalTemplate(
            targetAppTokenData: targetAppTokenData,
            text: text,
            isFavorite: isFavorite,
            useCount: useCount,
            lastUsedAt: lastUsedAt,
            createdAt: Date(timeIntervalSince1970: 0)
        )
    }
}
