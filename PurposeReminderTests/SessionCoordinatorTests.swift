import XCTest
@testable import PurposeReminder

@MainActor
final class SessionCoordinatorTests: XCTestCase {
    func testActiveCompletedFlow() async throws {
        let repository = InMemoryGoalSessionRepository()
        let clock = FixedTimeProvider(now: Date(timeIntervalSince1970: 1_700_000_000))
        let coordinator = SessionCoordinator(repository: repository, timeProvider: clock)

        try coordinator.beginGoalSelection()
        let started = try await coordinator.startSession(
            targetAppTokenData: Data("com.example.instagram".utf8),
            templateId: nil,
            goalText: "DM 3개만 답장",
            plannedDurationMinutes: 20
        )

        XCTAssertEqual(coordinator.state, .active(sessionId: started.id))
        XCTAssertEqual(started.status, .active)

        let completed = try await coordinator.completeSession()
        XCTAssertEqual(completed.status, .completed)
        XCTAssertEqual(coordinator.state, .idle)
    }

    func testExtendedFromActive() async throws {
        let repository = InMemoryGoalSessionRepository()
        let clock = FixedTimeProvider(now: Date(timeIntervalSince1970: 1_700_000_000))
        let coordinator = SessionCoordinator(repository: repository, timeProvider: clock)

        try coordinator.beginGoalSelection()
        let started = try await coordinator.startSession(
            targetAppTokenData: Data("com.example.youtube".utf8),
            templateId: nil,
            goalText: "영상 1개 확인",
            plannedDurationMinutes: 20
        )

        let extended = try await coordinator.extendSession(by: 10)

        XCTAssertEqual(extended.id, started.id)
        XCTAssertEqual(extended.status, .extended)
        XCTAssertEqual(extended.plannedDurationMinutes, 30)
        XCTAssertEqual(coordinator.state, .idle)
    }

    func testAbandonedFromReminded() async throws {
        let repository = InMemoryGoalSessionRepository()
        let clock = FixedTimeProvider(now: Date(timeIntervalSince1970: 1_700_000_000))
        let coordinator = SessionCoordinator(repository: repository, timeProvider: clock)

        try coordinator.beginGoalSelection()
        let started = try await coordinator.startSession(
            targetAppTokenData: Data("com.example.reddit".utf8),
            templateId: nil,
            goalText: "피드 5분만",
            plannedDurationMinutes: 15
        )
        try coordinator.markReminded()

        XCTAssertEqual(coordinator.state, .reminded(sessionId: started.id))

        let abandoned = try await coordinator.abandonSession()
        XCTAssertEqual(abandoned.status, .abandoned)
        XCTAssertEqual(coordinator.state, .idle)
    }

    func testTimedOutFromReminded() async throws {
        let repository = InMemoryGoalSessionRepository()
        let clock = FixedTimeProvider(now: Date(timeIntervalSince1970: 1_700_000_000))
        let coordinator = SessionCoordinator(repository: repository, timeProvider: clock)

        try coordinator.beginGoalSelection()
        _ = try await coordinator.startSession(
            targetAppTokenData: Data("com.example.twitter".utf8),
            templateId: nil,
            goalText: "알림만 확인",
            plannedDurationMinutes: 10
        )
        try coordinator.markReminded()

        let timedOut = try await coordinator.timeoutSession()
        XCTAssertEqual(timedOut.status, .timedOut)
        XCTAssertEqual(coordinator.state, .idle)
    }

    func testInvalidTransitionWithoutPendingGoal() async throws {
        let repository = InMemoryGoalSessionRepository()
        let coordinator = SessionCoordinator(repository: repository, timeProvider: FixedTimeProvider())

        do {
            _ = try await coordinator.startSession(
                targetAppTokenData: Data("com.example.instagram".utf8),
                templateId: nil,
                goalText: "테스트",
                plannedDurationMinutes: 20
            )
            XCTFail("expected invalid transition")
        } catch let error as SessionCoordinatorError {
            XCTAssertEqual(error, .invalidTransition(from: .idle, event: "startSession"))
        }
    }

    func testAttachToActiveSessionFromIdleThenComplete() async throws {
        let repository = InMemoryGoalSessionRepository()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let clock = FixedTimeProvider(now: now)
        let coordinator = SessionCoordinator(repository: repository, timeProvider: clock)

        let session = GoalSession(
            targetAppTokenData: Data("com.example.instagram".utf8),
            templateId: nil,
            goalTextSnapshot: "attach",
            startedAt: now,
            endedAt: nil,
            status: .active,
            plannedDurationMinutes: 20
        )
        try await repository.save(session)

        try await coordinator.attachToActiveSessionIfNeeded(sessionId: session.id)
        let completed = try await coordinator.completeSession()

        XCTAssertEqual(completed.id, session.id)
        XCTAssertEqual(completed.status, .completed)
        XCTAssertEqual(coordinator.state, .idle)
    }

    func testAttachFailsWhenSessionAlreadyEnded() async throws {
        let repository = InMemoryGoalSessionRepository()
        let coordinator = SessionCoordinator(repository: repository, timeProvider: FixedTimeProvider())

        let session = GoalSession(
            targetAppTokenData: Data("com.example.instagram".utf8),
            templateId: nil,
            goalTextSnapshot: "ended",
            startedAt: Date(timeIntervalSince1970: 1_700_000_000),
            endedAt: Date(timeIntervalSince1970: 1_700_000_100),
            status: .completed,
            plannedDurationMinutes: 20
        )
        try await repository.save(session)

        do {
            try await coordinator.attachToActiveSessionIfNeeded(sessionId: session.id)
            XCTFail("expected sessionNotActive")
        } catch let error as SessionCoordinatorError {
            XCTAssertEqual(error, .sessionNotActive)
        }
    }

    func testStartSessionFailsWhenAnotherActiveSessionAlreadyExists() async throws {
        let repository = InMemoryGoalSessionRepository()
        let coordinator = SessionCoordinator(repository: repository, timeProvider: FixedTimeProvider())

        let existing = GoalSession(
            targetAppTokenData: Data("com.example.instagram".utf8),
            templateId: nil,
            goalTextSnapshot: "existing",
            startedAt: Date(timeIntervalSince1970: 1_700_000_000),
            endedAt: nil,
            status: .active,
            plannedDurationMinutes: 20
        )
        try await repository.save(existing)

        try coordinator.beginGoalSelection()

        do {
            _ = try await coordinator.startSession(
                targetAppTokenData: Data("com.example.youtube".utf8),
                templateId: nil,
                goalText: "new",
                plannedDurationMinutes: 15
            )
            XCTFail("expected activeSessionAlreadyExists")
        } catch let error as SessionCoordinatorError {
            XCTAssertEqual(error, .activeSessionAlreadyExists)
            XCTAssertEqual(coordinator.state, .idle)
        }
    }
}

private struct FixedTimeProvider: TimeProviderProtocol {
    let now: Date

    init(now: Date = Date(timeIntervalSince1970: 1_700_000_000)) {
        self.now = now
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
