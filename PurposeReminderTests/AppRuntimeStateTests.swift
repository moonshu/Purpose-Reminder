import XCTest
@testable import PurposeReminder

@MainActor
final class AppRuntimeStateTests: XCTestCase {
    func testStartGoalRouteSelectsSessionTab() async {
        let repository = InMemoryAppRuntimeSessionRepository()
        let coordinator = SessionCoordinator(repository: repository)
        let targetTokenData = Data("target-token".utf8)
        let state = AppRuntimeState(
            shieldRouteInbox: ShieldRouteInboxStub(
                event: ShieldRouteEvent(
                    route: .startGoalSelection,
                    targetType: "application",
                    isPolicyManaged: true,
                    actionAt: 1_700_000_000,
                    targetTokenData: targetTokenData
                )
            ),
            timeoutInbox: SessionTimeoutInboxStub(event: nil),
            sessionRepository: repository,
            sessionCoordinator: coordinator
        )
        state.selectedTab = .history

        await state.handleAppActivated()

        XCTAssertEqual(state.selectedTab, .session)
        XCTAssertEqual(state.preferredSessionTargetTokenData, targetTokenData)
    }

    func testDismissRouteKeepsSelectedTab() async {
        let repository = InMemoryAppRuntimeSessionRepository()
        let coordinator = SessionCoordinator(repository: repository)
        let state = AppRuntimeState(
            shieldRouteInbox: ShieldRouteInboxStub(
                event: ShieldRouteEvent(
                    route: .dismissShield,
                    targetType: "application",
                    isPolicyManaged: true,
                    actionAt: 1_700_000_000,
                    targetTokenData: nil
                )
            ),
            timeoutInbox: SessionTimeoutInboxStub(event: nil),
            sessionRepository: repository,
            sessionCoordinator: coordinator
        )
        state.selectedTab = .policy

        await state.handleAppActivated()

        XCTAssertEqual(state.selectedTab, .policy)
    }

    func testTimeoutEventMarksLatestActiveSessionTimedOut() async throws {
        let repository = InMemoryAppRuntimeSessionRepository()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let active = GoalSession(
            targetAppTokenData: Data("com.example.instagram".utf8),
            templateId: nil,
            goalTextSnapshot: "테스트",
            startedAt: now,
            endedAt: nil,
            status: .active,
            plannedDurationMinutes: 20
        )
        try await repository.save(active)

        let coordinator = SessionCoordinator(repository: repository)
        let state = AppRuntimeState(
            shieldRouteInbox: ShieldRouteInboxStub(event: nil),
            timeoutInbox: SessionTimeoutInboxStub(
                event: SessionTimeoutEvent(
                    activityName: "focus-session",
                    reason: "intervalDidEnd",
                    occurredAt: now.timeIntervalSince1970 + 1_200
                )
            ),
            sessionRepository: repository,
            sessionCoordinator: coordinator
        )

        await state.handleAppActivated()

        let saved = try await repository.fetch(id: active.id)
        XCTAssertEqual(saved?.status, .timedOut)
    }
}

private final class ShieldRouteInboxStub: ShieldRouteInboxServicing {
    private var event: ShieldRouteEvent?

    init(event: ShieldRouteEvent?) {
        self.event = event
    }

    func consumeLastEvent() -> ShieldRouteEvent? {
        defer { event = nil }
        return event
    }
}

private final class SessionTimeoutInboxStub: SessionTimeoutInboxServicing {
    private var event: SessionTimeoutEvent?

    init(event: SessionTimeoutEvent?) {
        self.event = event
    }

    func consumeTimeoutEvent() -> SessionTimeoutEvent? {
        defer { event = nil }
        return event
    }
}

private actor AppRuntimeSessionStore {
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

private final class InMemoryAppRuntimeSessionRepository: GoalSessionRepository {
    private let store = AppRuntimeSessionStore()

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
