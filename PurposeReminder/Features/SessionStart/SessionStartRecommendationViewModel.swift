import SwiftUI

@MainActor
final class SessionStartRecommendationViewModel: ObservableObject {
    @Published private(set) var recommendations: [QuickGoalRecommendation] = []
    @Published private(set) var shouldShowCustomGoalInput = true
    @Published var customGoalText = ""
    @Published private(set) var startedSession: GoalSession?
    @Published private(set) var isLoading = false
    @Published private(set) var isStarting = false
    @Published var errorMessage: String?

    private let templateRepository: GoalTemplateRepository
    private let policyRepository: AppPolicyRepository
    private let sessionCoordinator: SessionCoordinator
    private let recommendationService: QuickGoalRecommendationServicing
    private let preferredAppTokenData: Data?

    private var selectedPolicy: AppPolicy?
    private var selectedTargetAppTokenData: Data?

    init(
        templateRepository: GoalTemplateRepository,
        policyRepository: AppPolicyRepository,
        sessionCoordinator: SessionCoordinator,
        recommendationService: QuickGoalRecommendationServicing = QuickGoalRecommendationService(),
        preferredAppTokenData: Data? = nil
    ) {
        self.templateRepository = templateRepository
        self.policyRepository = policyRepository
        self.sessionCoordinator = sessionCoordinator
        self.recommendationService = recommendationService
        self.preferredAppTokenData = preferredAppTokenData
    }

    convenience init(preferredAppTokenData: Data? = nil) {
        let context = SwiftDataStack.shared.mainContext
        let templateRepository = SwiftDataGoalTemplateRepository(context: context)
        let policyRepository = SwiftDataAppPolicyRepository(context: context)
        let sessionRepository = SwiftDataGoalSessionRepository(context: context)
        let sessionCoordinator = SessionCoordinator(repository: sessionRepository)

        self.init(
            templateRepository: templateRepository,
            policyRepository: policyRepository,
            sessionCoordinator: sessionCoordinator,
            recommendationService: QuickGoalRecommendationService(),
            preferredAppTokenData: preferredAppTokenData
        )
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let activePolicies = try await policyRepository.fetchAll().filter(\.isActive)

            guard let policy = resolvePolicy(from: activePolicies) else {
                selectedPolicy = nil
                selectedTargetAppTokenData = nil
                recommendations = []
                shouldShowCustomGoalInput = true
                errorMessage = "활성화된 앱 정책이 없습니다. 대상 앱 설정에서 정책을 먼저 저장해 주세요."
                return
            }

            selectedPolicy = policy
            selectedTargetAppTokenData = policy.appTokenData

            let templates = try await templateRepository.fetchAll()
            applyRecommendations(templates: templates)
            errorMessage = nil
        } catch {
            errorMessage = "빠른 목표를 불러오지 못했습니다. 다시 시도해 주세요."
        }
    }

    func startFromRecommendation(_ recommendation: QuickGoalRecommendation) async {
        await startSession(
            goalText: recommendation.template.text,
            templateId: recommendation.template.id,
            usedTemplate: recommendation.template
        )
    }

    func startFromCustomGoal() async {
        let trimmed = customGoalText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "새 목표를 입력해 주세요."
            return
        }

        await startSession(
            goalText: trimmed,
            templateId: nil,
            usedTemplate: nil
        )

        if startedSession != nil {
            customGoalText = ""
        }
    }

    var canStartCustomGoal: Bool {
        !customGoalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isStarting
    }

    private func startSession(
        goalText: String,
        templateId: UUID?,
        usedTemplate: GoalTemplate?
    ) async {
        guard let targetAppTokenData = selectedTargetAppTokenData else {
            errorMessage = "대상 앱 정책이 없어 세션을 시작할 수 없습니다."
            return
        }

        isStarting = true
        defer { isStarting = false }

        do {
            switch sessionCoordinator.state {
            case .idle:
                try sessionCoordinator.beginGoalSelection()
            case .pendingGoal:
                break
            default:
                errorMessage = "이미 진행 중인 세션이 있어 새로 시작할 수 없습니다."
                return
            }

            let duration = selectedPolicy?.defaultDurationMinutes ?? Constants.Session.defaultDurationMinutes
            let session = try await sessionCoordinator.startSession(
                targetAppTokenData: targetAppTokenData,
                templateId: templateId,
                goalText: goalText,
                plannedDurationMinutes: duration
            )
            startedSession = session
            errorMessage = nil

            if var usedTemplate {
                usedTemplate.useCount += 1
                usedTemplate.lastUsedAt = session.startedAt
                try await templateRepository.save(usedTemplate)

                let templates = try await templateRepository.fetchAll()
                applyRecommendations(templates: templates)
            }
        } catch {
            errorMessage = "세션 시작에 실패했습니다. 다시 시도해 주세요."
        }
    }

    private func applyRecommendations(templates: [GoalTemplate]) {
        let result = recommendationService.recommend(
            templates: templates,
            targetAppTokenData: selectedTargetAppTokenData,
            defaultTemplateId: selectedPolicy?.defaultTemplateId
        )

        recommendations = result.recommendations
        shouldShowCustomGoalInput = result.shouldShowCustomGoalInput
    }

    private func resolvePolicy(from activePolicies: [AppPolicy]) -> AppPolicy? {
        let sorted = activePolicies.sorted { $0.id.uuidString < $1.id.uuidString }

        if let preferredAppTokenData,
           let matched = sorted.first(where: { $0.appTokenData == preferredAppTokenData }) {
            return matched
        }

        return sorted.first
    }
}
