import XCTest
@testable import PurposeReminder

@MainActor
final class IntentSessionStarterTests: XCTestCase {
    func testQuickStartFailsWithoutActivePolicy() async {
        let starter = makeStarter(policies: [], templates: [])

        let result = await starter.startQuick(
            goalText: "DM 확인",
            durationMinutes: 20
        )

        XCTAssertFalse(result.didStartSession)
        XCTAssertEqual(result.message, "활성 정책이 없습니다. 앱에서 대상 앱 설정을 먼저 완료해 주세요.")
    }

    func testFavoriteStartFailsWithoutFavoriteTemplate() async {
        let policy = AppPolicy(appTokenData: Data("com.example.instagram".utf8))
        let starter = makeStarter(policies: [policy], templates: [])

        let result = await starter.startFavorite()

        XCTAssertFalse(result.didStartSession)
        XCTAssertEqual(result.message, "즐겨찾기 목표가 없습니다. 앱에서 즐겨찾기를 먼저 등록해 주세요.")
    }

    func testQuickStartCreatesSession() async throws {
        let policy = AppPolicy(
            appTokenData: Data("com.example.youtube".utf8),
            isActive: true,
            defaultDurationMinutes: 25,
            reminderOffsetMinutes: 5,
            defaultTemplateId: nil
        )
        let repository = InMemoryIntentGoalSessionRepository()
        let coordinator = SessionCoordinator(repository: repository)
        let starter = IntentSessionStarter(
            policyRepository: StubIntentPolicyRepository(policies: [policy]),
            templateRepository: StubIntentTemplateRepository(templates: []),
            sessionCoordinator: coordinator
        )

        let result = await starter.startQuick(
            goalText: "영상 하나만 확인",
            durationMinutes: -1
        )

        XCTAssertTrue(result.didStartSession)
        XCTAssertNotNil(result.session)
        XCTAssertEqual(result.session?.plannedDurationMinutes, 25)

        let sessions = try await repository.fetchAll()
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.goalTextSnapshot, "영상 하나만 확인")
    }

    func testQuickStartFailsWhenSessionAlreadyActive() async {
        let policy = AppPolicy(appTokenData: Data("com.example.reddit".utf8))
        let repository = InMemoryIntentGoalSessionRepository()
        let coordinator = SessionCoordinator(repository: repository)
        let starter = IntentSessionStarter(
            policyRepository: StubIntentPolicyRepository(policies: [policy]),
            templateRepository: StubIntentTemplateRepository(templates: []),
            sessionCoordinator: coordinator
        )

        let first = await starter.startQuick(goalText: "첫 세션", durationMinutes: 20)
        XCTAssertTrue(first.didStartSession)

        let second = await starter.startQuick(goalText: "두 번째 세션", durationMinutes: 20)

        XCTAssertFalse(second.didStartSession)
        XCTAssertEqual(second.message, "이미 진행 중인 세션이 있어 새 세션을 시작할 수 없습니다.")
    }

    private func makeStarter(
        policies: [AppPolicy],
        templates: [GoalTemplate]
    ) -> IntentSessionStarter {
        let sessionRepository = InMemoryIntentGoalSessionRepository()
        let coordinator = SessionCoordinator(repository: sessionRepository)
        return IntentSessionStarter(
            policyRepository: StubIntentPolicyRepository(policies: policies),
            templateRepository: StubIntentTemplateRepository(templates: templates),
            sessionCoordinator: coordinator
        )
    }
}

private final class StubIntentPolicyRepository: AppPolicyRepository {
    private var policies: [AppPolicy]

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

private final class StubIntentTemplateRepository: GoalTemplateRepository {
    private var templates: [GoalTemplate]

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

private actor IntentSessionStore {
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

private final class InMemoryIntentGoalSessionRepository: GoalSessionRepository {
    private let store = IntentSessionStore()

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
