import XCTest
import FamilyControls
import ManagedSettings
@testable import PurposeReminder

@MainActor
final class PolicySettingsViewModelTests: XCTestCase {
    func testSavePersistsDefaultTemplateId() async throws {
        let policy = AppPolicy(appTokenData: Data("app-token".utf8), defaultTemplateId: nil)
        let template = GoalTemplate(targetAppTokenData: nil, text: "기본 템플릿")

        let policyRepository = StubPolicyRepository(policies: [policy])
        let templateRepository = StubTemplateRepository(templates: [template])
        let viewModel = PolicySettingsViewModel(
            repository: policyRepository,
            templateRepository: templateRepository,
            appSelectionService: StubAppSelectionService(),
            shieldPolicyService: StubShieldPolicyService()
        )

        await viewModel.load()
        viewModel.updateDefaultTemplate(for: policy.id, templateId: template.id)
        await viewModel.save()

        let saved = try await policyRepository.fetch(id: policy.id)
        XCTAssertEqual(saved?.defaultTemplateId, template.id)
    }

    func testSaveClearsDanglingDefaultTemplateId() async throws {
        let danglingTemplateId = UUID()
        let policy = AppPolicy(
            appTokenData: Data("app-token".utf8),
            defaultTemplateId: danglingTemplateId
        )

        let policyRepository = StubPolicyRepository(policies: [policy])
        let templateRepository = StubTemplateRepository(templates: [])
        let viewModel = PolicySettingsViewModel(
            repository: policyRepository,
            templateRepository: templateRepository,
            appSelectionService: StubAppSelectionService(),
            shieldPolicyService: StubShieldPolicyService()
        )

        await viewModel.load()
        await viewModel.save()

        let saved = try await policyRepository.fetch(id: policy.id)
        XCTAssertNil(saved?.defaultTemplateId)
    }
}

private final class StubPolicyRepository: AppPolicyRepository {
    private(set) var policies: [AppPolicy]

    init(policies: [AppPolicy]) {
        self.policies = policies
    }

    func fetchAll() async throws -> [AppPolicy] {
        policies
    }

    func fetch(id: UUID) async throws -> AppPolicy? {
        policies.first(where: { $0.id == id })
    }

    func save(_ policy: AppPolicy) async throws {
        if let index = policies.firstIndex(where: { $0.id == policy.id }) {
            policies[index] = policy
        } else {
            policies.append(policy)
        }
    }

    func delete(id: UUID) async throws {
        policies.removeAll(where: { $0.id == id })
    }
}

private final class StubTemplateRepository: GoalTemplateRepository {
    private let templates: [GoalTemplate]

    init(templates: [GoalTemplate]) {
        self.templates = templates
    }

    func fetchAll() async throws -> [GoalTemplate] {
        templates
    }

    func fetch(forAppToken appTokenData: Data?) async throws -> [GoalTemplate] {
        templates.filter { $0.targetAppTokenData == appTokenData }
    }

    func fetchFavorites() async throws -> [GoalTemplate] {
        templates.filter(\.isFavorite)
    }

    func save(_ template: GoalTemplate) async throws {}

    func delete(id: UUID) async throws {}
}

private struct StubAppSelectionService: AppSelectionServicing {
    func makeSelection(from policies: [AppPolicy]) -> FamilyActivitySelection {
        FamilyActivitySelection()
    }

    func makePolicies(
        from selection: FamilyActivitySelection,
        existingPolicies: [AppPolicy],
        defaultDurationMinutes: Int,
        reminderOffsetMinutes: Int
    ) -> [AppPolicy] {
        existingPolicies
    }

    func encodeToken(_ token: ApplicationToken) throws -> Data {
        throw AppSelectionError.tokenEncodingFailed
    }

    func decodeToken(from data: Data) throws -> ApplicationToken {
        throw AppSelectionError.tokenDecodingFailed
    }
}

private struct StubShieldPolicyService: ShieldPolicyServicing {
    func applyPolicies(_ policies: [AppPolicy]) throws {}
    func clearAll() {}
}
