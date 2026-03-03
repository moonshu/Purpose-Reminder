import Foundation
import FamilyControls
import ManagedSettings

enum AppSelectionError: LocalizedError {
    case tokenEncodingFailed
    case tokenDecodingFailed

    var errorDescription: String? {
        switch self {
        case .tokenEncodingFailed:
            return "앱 토큰 인코딩에 실패했습니다."
        case .tokenDecodingFailed:
            return "앱 토큰 디코딩에 실패했습니다."
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
    func makeSelection(from policies: [AppPolicy]) -> FamilyActivitySelection {
        var selection = FamilyActivitySelection()
        let activePolicies = policies.filter(\.isActive)

        let tokens = activePolicies.compactMap { policy in
            try? decodeToken(from: policy.appTokenData)
        }

        selection.applicationTokens = Set(tokens)
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

        return selection.applicationTokens.compactMap { token in
            guard let tokenData = try? encodeToken(token) else {
                return nil
            }

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
            return try JSONEncoder().encode(token)
        } catch {
            throw AppSelectionError.tokenEncodingFailed
        }
    }

    func decodeToken(from data: Data) throws -> ApplicationToken {
        do {
            return try JSONDecoder().decode(ApplicationToken.self, from: data)
        } catch {
            throw AppSelectionError.tokenDecodingFailed
        }
    }
}
