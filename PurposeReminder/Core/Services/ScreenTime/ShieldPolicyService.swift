import Foundation
import ManagedSettings

enum ShieldPolicyError: LocalizedError {
    case invalidTokenData

    var errorDescription: String? {
        switch self {
        case .invalidTokenData:
            return "Shield 적용 중 앱 토큰을 읽을 수 없습니다."
        }
    }
}

protocol ShieldPolicyServicing {
    func applyPolicies(_ policies: [AppPolicy]) throws
    func clearAll()
}

final class ShieldPolicyService: ShieldPolicyServicing {
    private let store: ManagedSettingsStore

    init(store: ManagedSettingsStore = ManagedSettingsStore()) {
        self.store = store
    }

    func applyPolicies(_ policies: [AppPolicy]) throws {
        let activePolicies = policies.filter(\.isActive)

        let decodedTokens = try activePolicies.map { policy in
            do {
                return try JSONDecoder().decode(ApplicationToken.self, from: policy.appTokenData)
            } catch {
                throw ShieldPolicyError.invalidTokenData
            }
        }

        if decodedTokens.isEmpty {
            store.shield.applications = nil
            return
        }

        store.shield.applications = Set(decodedTokens)
    }

    func clearAll() {
        store.clearAllSettings()
    }
}
