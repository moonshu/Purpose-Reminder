import Foundation

struct IntentSessionStartResult {
    let didStartSession: Bool
    let message: String
    let session: GoalSession?

    static func failure(message: String) -> IntentSessionStartResult {
        IntentSessionStartResult(
            didStartSession: false,
            message: message,
            session: nil
        )
    }

    static func success(message: String, session: GoalSession) -> IntentSessionStartResult {
        IntentSessionStartResult(
            didStartSession: true,
            message: message,
            session: session
        )
    }
}

@MainActor
final class IntentSessionStarter {
    private let policyRepository: AppPolicyRepository
    private let templateRepository: GoalTemplateRepository
    private let sessionCoordinator: SessionCoordinator
    private let reminderScheduler: ReminderScheduling

    init(
        policyRepository: AppPolicyRepository,
        templateRepository: GoalTemplateRepository,
        sessionCoordinator: SessionCoordinator,
        reminderScheduler: ReminderScheduling
    ) {
        self.policyRepository = policyRepository
        self.templateRepository = templateRepository
        self.sessionCoordinator = sessionCoordinator
        self.reminderScheduler = reminderScheduler
    }

    convenience init() {
        let context = SwiftDataStack.shared.mainContext
        let policyRepository = SwiftDataAppPolicyRepository(context: context)
        let templateRepository = SwiftDataGoalTemplateRepository(context: context)
        let sessionRepository = SwiftDataGoalSessionRepository(context: context)
        let sessionCoordinator = SessionCoordinator(repository: sessionRepository)
        let reminderScheduler = ReminderScheduler(repository: sessionRepository)

        self.init(
            policyRepository: policyRepository,
            templateRepository: templateRepository,
            sessionCoordinator: sessionCoordinator,
            reminderScheduler: reminderScheduler
        )
    }

    func startQuick(goalText: String, durationMinutes: Int) async -> IntentSessionStartResult {
        let trimmedGoalText = goalText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedGoalText.isEmpty else {
            return .failure(message: "목표를 입력해 주세요.")
        }

        do {
            guard let policy = try await fetchActivePolicy() else {
                return .failure(message: "활성 정책이 없습니다. 앱에서 대상 앱 설정을 먼저 완료해 주세요.")
            }

            if let result = prepareCoordinatorIfNeeded() {
                return result
            }

            let duration = durationMinutes > 0 ? durationMinutes : policy.defaultDurationMinutes
            let session = try await sessionCoordinator.startSession(
                targetAppTokenData: policy.appTokenData,
                templateId: nil,
                goalText: trimmedGoalText,
                plannedDurationMinutes: duration
            )

            let reminderWarning = await scheduleReminderIfPossible(
                session: session,
                reminderOffsetMinutes: policy.reminderOffsetMinutes
            )

            let messageSuffix = reminderWarning.map { " \($0)" } ?? ""
            return .success(
                message: "\"\(session.goalTextSnapshot)\" 세션이 시작되었습니다. (\(session.plannedDurationMinutes)분)\(messageSuffix)",
                session: session
            )
        } catch SessionCoordinatorError.activeSessionAlreadyExists {
            return .failure(message: "이미 진행 중인 세션이 있어 새 세션을 시작할 수 없습니다.")
        } catch {
            return .failure(message: "세션 시작에 실패했습니다. 잠시 후 다시 시도해 주세요.")
        }
    }

    func startFavorite() async -> IntentSessionStartResult {
        do {
            let favorites = try await templateRepository.fetchFavorites()
            guard let favorite = pickFavorite(from: favorites) else {
                return .failure(message: "즐겨찾기 목표가 없습니다. 앱에서 즐겨찾기를 먼저 등록해 주세요.")
            }

            guard let policy = try await fetchActivePolicy() else {
                return .failure(message: "활성 정책이 없습니다. 앱에서 대상 앱 설정을 먼저 완료해 주세요.")
            }

            if let result = prepareCoordinatorIfNeeded() {
                return result
            }

            let session = try await sessionCoordinator.startSession(
                targetAppTokenData: policy.appTokenData,
                templateId: favorite.id,
                goalText: favorite.text,
                plannedDurationMinutes: policy.defaultDurationMinutes
            )

            let reminderWarning = await scheduleReminderIfPossible(
                session: session,
                reminderOffsetMinutes: policy.reminderOffsetMinutes
            )
            try await bumpFavoriteUsage(for: favorite, at: session.startedAt)

            let messageSuffix = reminderWarning.map { " \($0)" } ?? ""
            return .success(
                message: "\"\(session.goalTextSnapshot)\" 즐겨찾기 세션이 시작되었습니다.\(messageSuffix)",
                session: session
            )
        } catch SessionCoordinatorError.activeSessionAlreadyExists {
            return .failure(message: "이미 진행 중인 세션이 있어 새 세션을 시작할 수 없습니다.")
        } catch {
            return .failure(message: "즐겨찾기 세션 시작에 실패했습니다. 잠시 후 다시 시도해 주세요.")
        }
    }

    private func fetchActivePolicy() async throws -> AppPolicy? {
        let policies = try await policyRepository.fetchAll().filter(\.isActive)
        return policies.sorted { $0.id.uuidString < $1.id.uuidString }.first
    }

    private func pickFavorite(from templates: [GoalTemplate]) -> GoalTemplate? {
        templates.sorted { lhs, rhs in
            switch (lhs.lastUsedAt, rhs.lastUsedAt) {
            case let (lhsDate?, rhsDate?) where lhsDate != rhsDate:
                return lhsDate > rhsDate
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            default:
                break
            }

            if lhs.useCount != rhs.useCount {
                return lhs.useCount > rhs.useCount
            }

            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt > rhs.createdAt
            }

            return lhs.id.uuidString < rhs.id.uuidString
        }.first
    }

    private func prepareCoordinatorIfNeeded() -> IntentSessionStartResult? {
        do {
            switch sessionCoordinator.state {
            case .idle:
                try sessionCoordinator.beginGoalSelection()
            case .pendingGoal:
                break
            case .active, .reminded:
                return .failure(message: "이미 진행 중인 세션이 있어 새 세션을 시작할 수 없습니다.")
            }
        } catch {
            return .failure(message: "세션 상태를 준비하지 못했습니다. 잠시 후 다시 시도해 주세요.")
        }

        return nil
    }

    private func bumpFavoriteUsage(for template: GoalTemplate, at startedAt: Date) async throws {
        var updated = template
        updated.useCount += 1
        updated.lastUsedAt = startedAt
        try await templateRepository.save(updated)
    }

    private func scheduleReminderIfPossible(
        session: GoalSession,
        reminderOffsetMinutes: Int
    ) async -> String? {
        do {
            _ = try await reminderScheduler.scheduleReminder(
                session: session,
                reminderOffsetMinutes: reminderOffsetMinutes
            )
            return nil
        } catch {
            return "리마인드를 예약하지 못했지만 세션은 시작되었습니다."
        }
    }
}
