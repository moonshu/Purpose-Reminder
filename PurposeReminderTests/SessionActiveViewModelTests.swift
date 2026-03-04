import XCTest
@testable import PurposeReminder

@MainActor
final class SessionActiveViewModelTests: XCTestCase {
    func testLoadShowsLatestActiveSession() async throws {
        let repository = InMemorySessionActiveRepository()
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        let older = GoalSession(
            targetAppTokenData: Data("com.example.youtube".utf8),
            templateId: nil,
            goalTextSnapshot: "older",
            startedAt: now.addingTimeInterval(-600),
            endedAt: nil,
            status: .active,
            plannedDurationMinutes: 20
        )
        let latest = GoalSession(
            targetAppTokenData: Data("com.example.instagram".utf8),
            templateId: nil,
            goalTextSnapshot: "latest",
            startedAt: now,
            endedAt: nil,
            status: .active,
            plannedDurationMinutes: 20
        )
        try await repository.save(older)
        try await repository.save(latest)

        let coordinator = SessionCoordinator(repository: repository)
        let viewModel = SessionActiveViewModel(
            repository: repository,
            coordinator: coordinator,
            nowProvider: { now }
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.activeSession?.id, latest.id)
        viewModel.stopTimer()
    }

    func testCompleteUpdatesStatusToCompleted() async throws {
        let repository = InMemorySessionActiveRepository()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let session = GoalSession(
            targetAppTokenData: Data("com.example.reddit".utf8),
            templateId: nil,
            goalTextSnapshot: "complete",
            startedAt: now,
            endedAt: nil,
            status: .active,
            plannedDurationMinutes: 20
        )
        try await repository.save(session)

        let coordinator = SessionCoordinator(repository: repository)
        let viewModel = SessionActiveViewModel(
            repository: repository,
            coordinator: coordinator,
            nowProvider: { now }
        )

        await viewModel.load()
        await viewModel.complete()

        let saved = try await repository.fetch(id: session.id)
        XCTAssertEqual(saved?.status, .completed)
        XCTAssertNil(viewModel.activeSession)
    }

    func testExtendUsesDefaultExtensionMinutes() async throws {
        let repository = InMemorySessionActiveRepository()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let session = GoalSession(
            targetAppTokenData: Data("com.example.reddit".utf8),
            templateId: nil,
            goalTextSnapshot: "extend",
            startedAt: now,
            endedAt: nil,
            status: .active,
            plannedDurationMinutes: 20
        )
        try await repository.save(session)

        let coordinator = SessionCoordinator(repository: repository)
        let viewModel = SessionActiveViewModel(
            repository: repository,
            coordinator: coordinator,
            nowProvider: { now }
        )

        await viewModel.load()
        await viewModel.extend()

        let saved = try await repository.fetch(id: session.id)
        XCTAssertEqual(saved?.status, .extended)
        XCTAssertEqual(saved?.plannedDurationMinutes, 30)
    }

    func testLoadHandlesNoActiveSession() async {
        let repository = InMemorySessionActiveRepository()
        let coordinator = SessionCoordinator(repository: repository)
        let viewModel = SessionActiveViewModel(
            repository: repository,
            coordinator: coordinator
        )

        await viewModel.load()
        XCTAssertNil(viewModel.activeSession)
        XCTAssertEqual(viewModel.remainingSeconds, 0)
    }
}

private actor SessionActiveStore {
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
        reminderEvents.values.flatMap { $0 }.first(where: { $0.id == id })
    }
}

private final class InMemorySessionActiveRepository: GoalSessionRepository {
    private let store = SessionActiveStore()

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
