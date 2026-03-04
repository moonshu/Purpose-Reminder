import ManagedSettings
import Foundation
import OSLog

private struct ShieldRoutePayload: Codable {
    let route: String
    let targetType: String
    let isPolicyManaged: Bool
    let actionAt: TimeInterval
    let targetTokenData: Data?
}

private struct ShieldActionRouter {
    private let defaults: UserDefaults?
    private let logger = Logger(
        subsystem: "com.purposereminder.app",
        category: "ShieldActionExtension"
    )

    init(
        defaults: UserDefaults? = UserDefaults(
            suiteName: Constants.AppGroup.suiteName
        )
    ) {
        self.defaults = defaults
    }

    func record(
        route: ShieldRoute,
        targetType: String,
        isPolicyManaged: Bool,
        targetTokenData: Data?
    ) -> Bool {
        guard let defaults else {
            logger.error("App Group UserDefaults unavailable. route=\(route.rawValue, privacy: .public)")
            return false
        }

        let event = ShieldRoutePayload(
            route: route.rawValue,
            targetType: targetType,
            isPolicyManaged: isPolicyManaged,
            actionAt: Date().timeIntervalSince1970,
            targetTokenData: targetTokenData
        )

        do {
            let data = try JSONEncoder().encode(event)
            defaults.set(data, forKey: Constants.AppGroup.shieldLastEventKey)
            return true
        } catch {
            logger.error("Failed to encode route event: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }
}

final class ShieldActionExtension: ShieldActionDelegate {
    private let router = ShieldActionRouter()
    private let settingsStore = ManagedSettingsStore()
    private let tokenCodec = PolicyTargetTokenCodec()

    override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        let isPolicyManaged = settingsStore.shield.applications?.contains(application) ?? false
        let targetTokenData = try? tokenCodec.encode(.application(application))
        completionHandler(
            response(
                for: action,
                targetType: "application",
                isPolicyManaged: isPolicyManaged,
                targetTokenData: targetTokenData
            )
        )
    }

    override func handle(
        action: ShieldAction,
        for webDomain: WebDomainToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        let isPolicyManaged = settingsStore.shield.webDomains?.contains(webDomain) ?? false
        let targetTokenData = try? tokenCodec.encode(.webDomain(webDomain))
        completionHandler(
            response(
                for: action,
                targetType: "webDomain",
                isPolicyManaged: isPolicyManaged,
                targetTokenData: targetTokenData
            )
        )
    }

    override func handle(
        action: ShieldAction,
        for category: ActivityCategoryToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        let hasApplicationCategoryPolicy = settingsStore.shield.applicationCategories
            .map { $0 != .none } ?? false
        let hasWebDomainCategoryPolicy = settingsStore.shield.webDomainCategories
            .map { $0 != .none } ?? false
        let hasCategoryPolicy = hasApplicationCategoryPolicy || hasWebDomainCategoryPolicy
        let targetTokenData = try? tokenCodec.encode(.category(category))
        completionHandler(
            response(
                for: action,
                targetType: "category",
                isPolicyManaged: hasCategoryPolicy,
                targetTokenData: targetTokenData
            )
        )
    }

    private func response(
        for action: ShieldAction,
        targetType: String,
        isPolicyManaged: Bool,
        targetTokenData: Data?
    ) -> ShieldActionResponse {
        switch action {
        case .primaryButtonPressed:
            let isRecorded = router.record(
                route: .startGoalSelection,
                targetType: targetType,
                isPolicyManaged: isPolicyManaged,
                targetTokenData: targetTokenData
            )
            return isRecorded ? .defer : .close
        case .secondaryButtonPressed:
            _ = router.record(
                route: .dismissShield,
                targetType: targetType,
                isPolicyManaged: isPolicyManaged,
                targetTokenData: targetTokenData
            )
            return .close
        @unknown default:
            return .close
        }
    }
}
