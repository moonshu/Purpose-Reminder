import XCTest
@testable import PurposeReminder

@MainActor
final class SessionStartRecommendationViewModelTests: XCTestCase {
    func testStartFromCustomGoalSchedulesReminder() async {
        let policy = AppPolicy(
            appTokenData: Data("com.example.instagram".utf8),
            isActive: true,
            defaultDurationMinutes: 20,
            reminderOffsetMinutes: 7,
            defaultTemplateId: nil
        )
        let policyRepository = StubAppPolicyRepository(policies: [policy])
        let templateRepository = StubGoalTemplateRepository(templates: [])
        let sessionRepository = InMemoryGoalSessionRepository()
        let coordinator = SessionCoordinator(repository: sessionRepository)
        let reminderScheduler = ReminderSchedulerSpy()

        let viewModel = SessionStartRecommendationViewModel(
            templateRepository: templateRepository,
            policyRepository: policyRepository,
            sessionCoordinator: coordinator,
            reminderScheduler: reminderScheduler,
            recommendationService: QuickGoalRecommendationService()
        )

        await viewModel.load()
        viewModel.customGoalText = "DM 3개만 답장"
        await viewModel.startFromCustomGoal()

        XCTAssertNotNil(viewModel.startedSession)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.warningMessage)
        XCTAssertEqual(reminderScheduler.scheduledCalls.count, 1)
        XCTAssertEqual(reminderScheduler.scheduledCalls.first?.reminderOffsetMinutes, 7)
    }

    func testStartFromCustomGoalKeepsSessionWhenReminderFails() async {
        let policy = AppPolicy(
            appTokenData: Data("com.example.youtube".utf8),
            isActive: true,
            defaultDurationMinutes: 20,
            reminderOffsetMinutes: 5,
            defaultTemplateId: nil
        )
        let policyRepository = StubAppPolicyRepository(policies: [policy])
        let templateRepository = StubGoalTemplateRepository(templates: [])
        let sessionRepository = InMemoryGoalSessionRepository()
        let coordinator = SessionCoordinator(repository: sessionRepository)
        let reminderScheduler = ReminderSchedulerSpy()
        reminderScheduler.shouldThrow = true

        let viewModel = SessionStartRecommendationViewModel(
            templateRepository: templateRepository,
            policyRepository: policyRepository,
            sessionCoordinator: coordinator,
            reminderScheduler: reminderScheduler,
            recommendationService: QuickGoalRecommendationService()
        )

        await viewModel.load()
        viewModel.customGoalText = "영상 하나만 확인"
        await viewModel.startFromCustomGoal()

        XCTAssertNotNil(viewModel.startedSession)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.warningMessage, "리마인드를 예약하지 못했습니다. 세션은 계속 진행됩니다.")
        XCTAssertEqual(reminderScheduler.scheduledCalls.count, 1)
    }
}

private final class StubAppPolicyRepository: AppPolicyRepository {
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

private final class StubGoalTemplateRepository: GoalTemplateRepository {
    private(set) var templates: [GoalTemplate]

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

private enum ReminderSchedulerSpyError: Error {
    case forcedFailure
}

private final class ReminderSchedulerSpy: ReminderScheduling {
    struct Call {
        let session: GoalSession
        let reminderOffsetMinutes: Int
    }

    var scheduledCalls: [Call] = []
    var shouldThrow = false

    func scheduleReminder(
        session: GoalSession,
        reminderOffsetMinutes: Int
    ) async throws -> ReminderScheduleResult {
        scheduledCalls.append(
            Call(session: session, reminderOffsetMinutes: reminderOffsetMinutes)
        )

        if shouldThrow {
            throw ReminderSchedulerSpyError.forcedFailure
        }

        let event = ReminderEvent(
            sessionId: session.id,
            scheduledAt: session.startedAt.addingTimeInterval(TimeInterval(reminderOffsetMinutes * 60))
        )
        return ReminderScheduleResult(
            event: event,
            requestIdentifier: "spy-\(event.id.uuidString)"
        )
    }
}

private actor SessionStore {
    var sessions: [UUID: GoalSession] = [:]
    var reminderEvents: [UUID: [ReminderEvent]] = [:]

    func allSessions() -> [GoalSession] {
        sessions.values.sorted(by: { $0.startedAt < $1.startedAt })
    }

    func session(id: UUID) -> GoalSession? {
        sessions[id]
    }

    func sessions(from startDate: Date, to endDate: Date) -> [GoalSession] {
        sessions.values.filter { $0.startedAt >= startDate && $0.startedAt <= endDate }
    }

    func saveSession(_ session: GoalSession) {
        sessions[session.id] = session
    }

    func deleteSession(id: UUID) {
        sessions.removeValue(forKey: id)
        reminderEvents.removeValue(forKey: id)
    }

    func saveReminder(_ event: ReminderEvent) {
        var events = reminderEvents[event.sessionId] ?? []
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
        } else {
            events.append(event)
        }
        reminderEvents[event.sessionId] = events
    }

    func reminders(sessionId: UUID) -> [ReminderEvent] {
        reminderEvents[sessionId] ?? []
    }

    func reminder(id: UUID) -> ReminderEvent? {
        reminderEvents.values
            .flatMap { $0 }
            .first(where: { $0.id == id })
    }
}

private final class InMemoryGoalSessionRepository: GoalSessionRepository {
    private let store = SessionStore()

    func fetchAll() async throws -> [GoalSession] {
        await store.allSessions()
    }

    func fetch(id: UUID) async throws -> GoalSession? {
        await store.session(id: id)
    }

    func fetch(from startDate: Date, to endDate: Date) async throws -> [GoalSession] {
        await store.sessions(from: startDate, to: endDate)
    }

    func save(_ session: GoalSession) async throws {
        await store.saveSession(session)
    }

    func delete(id: UUID) async throws {
        await store.deleteSession(id: id)
    }

    func saveReminderEvent(_ event: ReminderEvent) async throws {
        await store.saveReminder(event)
    }

    func fetchReminderEvents(sessionId: UUID) async throws -> [ReminderEvent] {
        await store.reminders(sessionId: sessionId)
    }

    func fetchReminderEvent(id: UUID) async throws -> ReminderEvent? {
        await store.reminder(id: id)
    }
}
