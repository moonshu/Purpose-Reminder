import Foundation
import FamilyControls
import ManagedSettings

enum AppSelectionError: LocalizedError {
    case tokenEncodingFailed
    case tokenDecodingFailed
    case unexpectedTokenType

    var errorDescription: String? {
        switch self {
        case .tokenEncodingFailed:
            return "앱 토큰 인코딩에 실패했습니다."
        case .tokenDecodingFailed:
            return "앱 토큰 디코딩에 실패했습니다."
        case .unexpectedTokenType:
            return "앱 정책 타입이 올바르지 않습니다."
        }
    }
}

protocol AppSelectionServicing {
    func makeSelection(from policies: [AppPolicy]) -> FamilyActivitySelection
    func makePolicies(
        from selection: FamilyActivitySelection,
        existingPolicies: [AppPolicy],
        defaultDurationMinutes: Int,
        reminderOffsetMinutes: Int
    ) -> [AppPolicy]
    func encodeToken(_ token: ApplicationToken) throws -> Data
    func decodeToken(from data: Data) throws -> ApplicationToken
}

struct AppSelectionService: AppSelectionServicing {
    private let codec = PolicyTargetTokenCodec()

    func makeSelection(from policies: [AppPolicy]) -> FamilyActivitySelection {
        var selection = FamilyActivitySelection()
        let activePolicies = policies.filter(\.isActive)
        var applicationTokens = Set<ApplicationToken>()
        var categoryTokens = Set<ActivityCategoryToken>()
        var webDomainTokens = Set<WebDomainToken>()

        for policy in activePolicies {
            guard let target = try? codec.decode(from: policy.appTokenData) else {
                continue
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

        selection.applicationTokens = applicationTokens
        selection.categoryTokens = categoryTokens
        selection.webDomainTokens = webDomainTokens
        return selection
    }

    func makePolicies(
        from selection: FamilyActivitySelection,
        existingPolicies: [AppPolicy],
        defaultDurationMinutes: Int,
        reminderOffsetMinutes: Int
    ) -> [AppPolicy] {
        let existingByToken = Dictionary(
            uniqueKeysWithValues: existingPolicies.map { ($0.appTokenData, $0) }
        )

        let selectedTokenData = selection.applicationTokens.compactMap { token in
            try? codec.encode(.application(token))
        } + selection.categoryTokens.compactMap { token in
            try? codec.encode(.category(token))
        } + selection.webDomainTokens.compactMap { token in
            try? codec.encode(.webDomain(token))
        }

        return selectedTokenData.compactMap { tokenData in
            if var existing = existingByToken[tokenData] {
                existing.isActive = true
                existing.defaultDurationMinutes = existing.defaultDurationMinutes > 0
                    ? existing.defaultDurationMinutes
                    : defaultDurationMinutes
                existing.reminderOffsetMinutes = existing.reminderOffsetMinutes > 0
                    ? existing.reminderOffsetMinutes
                    : reminderOffsetMinutes
                return existing
            }

            return AppPolicy(
                appTokenData: tokenData,
                isActive: true,
                defaultDurationMinutes: defaultDurationMinutes,
                reminderOffsetMinutes: reminderOffsetMinutes,
                defaultTemplateId: nil
            )
        }
    }

    func encodeToken(_ token: ApplicationToken) throws -> Data {
        do {
            return try codec.encode(.application(token))
        } catch {
            throw AppSelectionError.tokenEncodingFailed
        }
    }

    func decodeToken(from data: Data) throws -> ApplicationToken {
        do {
            let target = try codec.decode(from: data)
            guard case let .application(token) = target else {
                throw AppSelectionError.unexpectedTokenType
            }
            return token
        } catch let error as AppSelectionError {
            throw error
        } catch {
            throw AppSelectionError.tokenDecodingFailed
        }
    }
}
