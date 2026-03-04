import XCTest
@testable import PurposeReminder

final class SessionTimeoutInboxServiceTests: XCTestCase {
    func testConsumeDecodesAndClearsEvent() throws {
        let suiteName = "SessionTimeoutInboxServiceTests.\(UUID().uuidString)"
        let defaults = try makeDefaults(suiteName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let event = SessionTimeoutEvent(
            activityName: "focus-session",
            reason: "intervalDidEnd",
            occurredAt: 1_700_000_000
        )
        defaults.set(
            try JSONEncoder().encode(event),
            forKey: Constants.AppGroup.timeoutLastEventKey
        )

        let service = SessionTimeoutInboxService(userDefaults: defaults)
        let consumed = service.consumeTimeoutEvent()

        XCTAssertEqual(consumed, event)
        XCTAssertNil(defaults.data(forKey: Constants.AppGroup.timeoutLastEventKey))
    }

    func testConsumeClearsMalformedPayload() throws {
        let suiteName = "SessionTimeoutInboxServiceTests.\(UUID().uuidString)"
        let defaults = try makeDefaults(suiteName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(Data("not-json".utf8), forKey: Constants.AppGroup.timeoutLastEventKey)

        let service = SessionTimeoutInboxService(userDefaults: defaults)
        XCTAssertNil(service.consumeTimeoutEvent())
        XCTAssertNil(defaults.data(forKey: Constants.AppGroup.timeoutLastEventKey))
    }

    private func makeDefaults(suiteName: String) throws -> UserDefaults {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw NSError(domain: "SessionTimeoutInboxServiceTests", code: 1)
        }
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
