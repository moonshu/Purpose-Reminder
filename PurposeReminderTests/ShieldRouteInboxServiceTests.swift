import XCTest
@testable import PurposeReminder

final class ShieldRouteInboxServiceTests: XCTestCase {
    func testConsumeDecodesAndClearsEvent() throws {
        let suiteName = "ShieldRouteInboxServiceTests.\(UUID().uuidString)"
        let defaults = try makeDefaults(suiteName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let targetTokenData = Data("encoded-target".utf8)

        let payload: [String: Any] = [
            "route": "startGoalSelection",
            "targetType": "application",
            "isPolicyManaged": true,
            "actionAt": 1_700_000_000.0,
            "targetTokenData": targetTokenData.base64EncodedString()
        ]
        let data = try JSONSerialization.data(withJSONObject: payload)
        defaults.set(data, forKey: Constants.AppGroup.shieldLastEventKey)

        let service = ShieldRouteInboxService(userDefaults: defaults)
        let event = service.consumeLastEvent()

        XCTAssertEqual(event?.route, .startGoalSelection)
        XCTAssertEqual(event?.targetType, "application")
        XCTAssertEqual(event?.isPolicyManaged, true)
        XCTAssertEqual(event?.targetTokenData, targetTokenData)
        XCTAssertNil(defaults.data(forKey: Constants.AppGroup.shieldLastEventKey))
    }

    func testConsumeReturnsNilWhenNoEvent() throws {
        let suiteName = "ShieldRouteInboxServiceTests.\(UUID().uuidString)"
        let defaults = try makeDefaults(suiteName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let service = ShieldRouteInboxService(userDefaults: defaults)
        XCTAssertNil(service.consumeLastEvent())
    }

    func testConsumeClearsMalformedPayload() throws {
        let suiteName = "ShieldRouteInboxServiceTests.\(UUID().uuidString)"
        let defaults = try makeDefaults(suiteName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(Data("not-json".utf8), forKey: Constants.AppGroup.shieldLastEventKey)

        let service = ShieldRouteInboxService(userDefaults: defaults)
        XCTAssertNil(service.consumeLastEvent())
        XCTAssertNil(defaults.data(forKey: Constants.AppGroup.shieldLastEventKey))
    }

    private func makeDefaults(suiteName: String) throws -> UserDefaults {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw NSError(domain: "ShieldRouteInboxServiceTests", code: 1)
        }
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
