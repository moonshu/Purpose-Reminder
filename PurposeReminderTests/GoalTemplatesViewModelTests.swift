import XCTest
@testable import PurposeReminder

@MainActor
final class GoalTemplatesViewModelTests: XCTestCase {
    func testCreateTemplateRejectsBlankText() async {
        let repository = InMemoryGoalTemplateRepository()
        let viewModel = GoalTemplatesViewModel(repository: repository)

        viewModel.draftText = "   "
        await viewModel.createTemplate()

        XCTAssertEqual(viewModel.errorMessage, "템플릿 문구를 입력해 주세요.")
    }

    func testCreateTemplateRejectsDuplicateInSameScope() async throws {
        let repository = InMemoryGoalTemplateRepository()
        let existing = GoalTemplate(
            targetAppTokenData: nil,
            text: "DM 3개만 답장",
            isFavorite: false,
            useCount: 0,
            lastUsedAt: nil,
            createdAt: Date()
        )
        try await repository.save(existing)

        let viewModel = GoalTemplatesViewModel(repository: repository)
        await viewModel.load()
        viewModel.draftText = "DM 3개만 답장"
        await viewModel.createTemplate()

        XCTAssertEqual(viewModel.errorMessage, "동일한 템플릿이 이미 존재합니다.")
    }

    func testToggleFavoritePersists() async throws {
        let repository = InMemoryGoalTemplateRepository()
        let template = GoalTemplate(
            targetAppTokenData: nil,
            text: "영상 1개만 확인",
            isFavorite: false,
            useCount: 0,
            lastUsedAt: nil,
            createdAt: Date()
        )
        try await repository.save(template)

        let viewModel = GoalTemplatesViewModel(repository: repository)
        await viewModel.load()
        await viewModel.toggleFavorite(id: template.id)

        let saved = try await repository.fetchAll().first(where: { $0.id == template.id })
        XCTAssertEqual(saved?.isFavorite, true)
    }
}

private final class InMemoryGoalTemplateRepository: GoalTemplateRepository {
    private var templates: [GoalTemplate] = []

    func fetchAll() async throws -> [GoalTemplate] {
        templates
    }

    func fetch(forAppToken appTokenData: Data?) async throws -> [GoalTemplate] {
        templates.filter { $0.targetAppTokenData == appTokenData }
    }

    func fetchFavorites() async throws -> [GoalTemplate] {
        templates.filter(\.isFavorite)
    }

    func save(_ template: GoalTemplate) async throws {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
        } else {
            templates.append(template)
        }
    }

    func delete(id: UUID) async throws {
        templates.removeAll(where: { $0.id == id })
    }
}
