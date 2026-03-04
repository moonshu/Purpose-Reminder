import Foundation

struct SessionTimeoutEvent: Codable, Equatable {
    let activityName: String
    let reason: String
    let occurredAt: TimeInterval
}

protocol SessionTimeoutInboxServicing {
    func consumeTimeoutEvent() -> SessionTimeoutEvent?
}

struct SessionTimeoutInboxService: SessionTimeoutInboxServicing {
    private let userDefaults: UserDefaults?

    init(
        userDefaults: UserDefaults? = UserDefaults(
            suiteName: Constants.AppGroup.suiteName
        )
    ) {
        self.userDefaults = userDefaults
    }

    func consumeTimeoutEvent() -> SessionTimeoutEvent? {
        guard let userDefaults,
              let data = userDefaults.data(forKey: Constants.AppGroup.timeoutLastEventKey) else {
            return nil
        }

        // Consume-once: always clear regardless of decode success.
        userDefaults.removeObject(forKey: Constants.AppGroup.timeoutLastEventKey)

        return try? JSONDecoder().decode(SessionTimeoutEvent.self, from: data)
    }
}
