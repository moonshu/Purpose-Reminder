import Foundation
import ManagedSettings

enum ShieldPolicyError: LocalizedError {
    case invalidTokenData

    var errorDescription: String? {
        switch self {
        case .invalidTokenData:
            return "Shield 적용 중 정책 대상 토큰을 읽을 수 없습니다."
        }
    }
}

protocol ShieldPolicyServicing {
    func applyPolicies(_ policies: [AppPolicy]) throws
    func clearAll()
}

final class ShieldPolicyService: ShieldPolicyServicing {
    private let store: ManagedSettingsStore
    private let tokenCodec = PolicyTargetTokenCodec()

    init(store: ManagedSettingsStore = ManagedSettingsStore()) {
        self.store = store
    }

    func applyPolicies(_ policies: [AppPolicy]) throws {
        let activePolicies = policies.filter(\.isActive)
        var applicationTokens = Set<ApplicationToken>()
        var categoryTokens = Set<ActivityCategoryToken>()
        var webDomainTokens = Set<WebDomainToken>()

        for policy in activePolicies {
            let target: PolicyTargetToken
            do {
                target = try tokenCodec.decode(from: policy.appTokenData)
            } catch {
                throw ShieldPolicyError.invalidTokenData
            }

            switch target {
            case .application(let token):
                applicationTokens.insert(token)
            case .category(let token):
                categoryTokens.insert(token)
            case .webDomain(let token):
                webDomainTokens.insert(token)
            }
        }

        store.shield.applications = applicationTokens.isEmpty ? nil : applicationTokens
        store.shield.webDomains = webDomainTokens.isEmpty ? nil : webDomainTokens

        if categoryTokens.isEmpty {
            store.shield.applicationCategories = nil
            store.shield.webDomainCategories = nil
        } else {
            store.shield.applicationCategories = .specific(categoryTokens)
            store.shield.webDomainCategories = .specific(categoryTokens)
        }
    }

    func clearAll() {
        store.clearAllSettings()
    }
}
