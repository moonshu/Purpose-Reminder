import XCTest
@testable import PurposeReminder

@MainActor
final class HistoryViewModelTests: XCTestCase {
    func testEmptySummaryWhenNoSessionsToday() async {
        let now = makeDate(year: 2026, month: 3, day: 4, hour: 10, minute: 0)
        let repository = StubHistoryRepository(sessions: [])
        let viewModel = HistoryViewModel(
            repository: repository,
            calendar: calendar,
            nowProvider: { now }
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.summary, .empty)
        XCTAssertTrue(viewModel.recentSessions.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testCompletionRateCalculation() async {
        let now = makeDate(year: 2026, month: 3, day: 4, hour: 12, minute: 0)
        let sessions = [
            makeSession(status: .completed, startedAt: makeDate(year: 2026, month: 3, day: 4, hour: 9, minute: 0)),
            makeSession(status: .abandoned, startedAt: makeDate(year: 2026, month: 3, day: 4, hour: 10, minute: 0))
        ]
        let repository = StubHistoryRepository(sessions: sessions)
        let viewModel = HistoryViewModel(
            repository: repository,
            calendar: calendar,
            nowProvider: { now }
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.summary.totalToday, 2)
        XCTAssertEqual(viewModel.summary.completedToday, 1)
        XCTAssertEqual(viewModel.summary.abandonedToday, 1)
        XCTAssertEqual(viewModel.summary.completionRate, 0.5, accuracy: 0.0001)
    }

    func testTodayFilterExcludesYesterdayFromSummary() async {
        let now = makeDate(year: 2026, month: 3, day: 4, hour: 12, minute: 0)
        let yesterdaySession = makeSession(
            status: .completed,
            startedAt: makeDate(year: 2026, month: 3, day: 3, hour: 23, minute: 50)
        )
        let todaySession = makeSession(
            status: .completed,
            startedAt: makeDate(year: 2026, month: 3, day: 4, hour: 9, minute: 0)
        )

        let repository = StubHistoryRepository(sessions: [yesterdaySession, todaySession])
        let viewModel = HistoryViewModel(
            repository: repository,
            calendar: calendar,
            nowProvider: { now }
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.summary.totalToday, 1)
        XCTAssertEqual(viewModel.summary.completedToday, 1)
        XCTAssertEqual(viewModel.recentSessions.count, 2)
    }

    func testRecentSessionsSortedDescendingByStartedAt() async {
        let now = makeDate(year: 2026, month: 3, day: 4, hour: 12, minute: 0)
        let older = makeSession(
            status: .completed,
            startedAt: makeDate(year: 2026, month: 3, day: 4, hour: 8, minute: 0)
        )
        let newer = makeSession(
            status: .extended,
            startedAt: makeDate(year: 2026, month: 3, day: 4, hour: 11, minute: 0)
        )

        let repository = StubHistoryRepository(sessions: [older, newer])
        let viewModel = HistoryViewModel(
            repository: repository,
            calendar: calendar,
            nowProvider: { now }
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.recentSessions.map(\.id), [newer.id, older.id])
    }

    private let calendar: Calendar = {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return value
    }()

    private func makeSession(status: SessionStatus, startedAt: Date) -> GoalSession {
        GoalSession(
            targetAppTokenData: Data("app".utf8),
            templateId: nil,
            goalTextSnapshot: "테스트 목표",
            startedAt: startedAt,
            endedAt: status == .active ? nil : startedAt.addingTimeInterval(600),
            status: status,
            plannedDurationMinutes: 20
        )
    }

    private func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int
    ) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = 0
        components.timeZone = TimeZone(secondsFromGMT: 0)
        return calendar.date(from: components) ?? Date(timeIntervalSince1970: 0)
    }
}

private final class StubHistoryRepository: GoalSessionRepository {
    private var sessions: [GoalSession]
    private var reminderEvents: [ReminderEvent] = []

    init(sessions: [GoalSession]) {
        self.sessions = sessions
    }

    func fetchAll() async throws -> [GoalSession] {
        sessions
    }

    func fetch(id: UUID) async throws -> GoalSession? {
        sessions.first(where: { $0.id == id })
    }

    func fetch(from startDate: Date, to endDate: Date) async throws -> [GoalSession] {
        sessions.filter { session in
            session.startedAt >= startDate && session.startedAt <= endDate
        }
    }

    func save(_ session: GoalSession) async throws {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        } else {
            sessions.append(session)
        }
    }

    func delete(id: UUID) async throws {
        sessions.removeAll(where: { $0.id == id })
        reminderEvents.removeAll(where: { $0.sessionId == id })
    }

    func saveReminderEvent(_ event: ReminderEvent) async throws {
        if let index = reminderEvents.firstIndex(where: { $0.id == event.id }) {
            reminderEvents[index] = event
        } else {
            reminderEvents.append(event)
        }
    }

    func fetchReminderEvents(sessionId: UUID) async throws -> [ReminderEvent] {
        reminderEvents.filter { $0.sessionId == sessionId }
    }

    func fetchReminderEvent(id: UUID) async throws -> ReminderEvent? {
        reminderEvents.first(where: { $0.id == id })
    }
}
