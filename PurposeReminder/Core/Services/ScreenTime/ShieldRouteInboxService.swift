import Foundation

enum ShieldRoute: String, Equatable {
    case startGoalSelection
    case dismissShield
}

struct ShieldRouteEvent: Equatable {
    let route: ShieldRoute
    let targetType: String
    let isPolicyManaged: Bool
    let actionAt: TimeInterval
    let targetTokenData: Data?
}

protocol ShieldRouteInboxServicing {
    func consumeLastEvent() -> ShieldRouteEvent?
}

struct ShieldRouteInboxService: ShieldRouteInboxServicing {
    private struct Payload: Codable {
        let route: String
        let targetType: String
        let isPolicyManaged: Bool
        let actionAt: TimeInterval
        let targetTokenData: Data?
    }

    private let userDefaults: UserDefaults?

    init(
        userDefaults: UserDefaults? = UserDefaults(
            suiteName: Constants.AppGroup.suiteName
        )
    ) {
        self.userDefaults = userDefaults
    }

    func consumeLastEvent() -> ShieldRouteEvent? {
        guard let userDefaults,
              let data = userDefaults.data(forKey: Constants.AppGroup.shieldLastEventKey) else {
            return nil
        }

        // Consume-once: always clear regardless of decode success.
        userDefaults.removeObject(forKey: Constants.AppGroup.shieldLastEventKey)

        guard let payload = try? JSONDecoder().decode(Payload.self, from: data),
              let route = ShieldRoute(rawValue: payload.route) else {
            return nil
        }

        return ShieldRouteEvent(
            route: route,
            targetType: payload.targetType,
            isPolicyManaged: payload.isPolicyManaged,
            actionAt: payload.actionAt,
            targetTokenData: payload.targetTokenData
        )
    }
}
