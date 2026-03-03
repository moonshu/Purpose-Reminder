import XCTest
import UserNotifications

@MainActor
final class ReminderSchedulerTests: XCTestCase {
    func testReminderDateCalculation() async throws {
        let repository = InMemoryReminderRepository()
        let notificationCenter = NotificationCenterSpy()
        let scheduler = ReminderScheduler(
            repository: repository,
            notificationCenter: notificationCenter,
            timeProvider: FixedReminderTimeProvider(now: Date(timeIntervalSince1970: 1_700_000_000))
        )

        let session = GoalSession(
            targetAppTokenData: Data("com.example.instagram".utf8),
            templateId: nil,
            goalTextSnapshot: "DM 확인",
            startedAt: Date(timeIntervalSince1970: 1_700_000_000),
            endedAt: nil,
            status: .active,
            plannedDurationMinutes: 20
        )

        let scheduledAt = scheduler.reminderDate(session: session, reminderOffsetMinutes: 5)
        XCTAssertEqual(scheduledAt, Date(timeIntervalSince1970: 1_700_000_900))
    }

    func testScheduleReminderPersistsEventAndAddsNotification() async throws {
        let repository = InMemoryReminderRepository()
        let notificationCenter = NotificationCenterSpy()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let scheduler = ReminderScheduler(
            repository: repository,
            notificationCenter: notificationCenter,
            timeProvider: FixedReminderTimeProvider(now: now)
        )

        let session = GoalSession(
            targetAppTokenData: Data("com.example.youtube".utf8),
            templateId: nil,
            goalTextSnapshot: "영상 하나만",
            startedAt: now,
            endedAt: nil,
            status: .active,
            plannedDurationMinutes: 20
        )
        try await repository.save(session)

        let result = try await scheduler.scheduleReminder(sessionId: session.id, reminderOffsetMinutes: 5)

        let events = try await repository.fetchReminderEvents(sessionId: session.id)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.id, result.event.id)
        XCTAssertEqual(events.first?.scheduledAt, Date(timeIntervalSince1970: 1_700_000_900))

        XCTAssertEqual(notificationCenter.requests.count, 1)
        XCTAssertEqual(notificationCenter.requests.first?.identifier, result.requestIdentifier)
        XCTAssertEqual(notificationCenter.requests.first?.content.categoryIdentifier, Constants.Notification.reminderCategoryIdentifier)
    }

    func testMarkReminderFiredAndAction() async throws {
        let repository = InMemoryReminderRepository()
        let notificationCenter = NotificationCenterSpy()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let scheduler = ReminderScheduler(
            repository: repository,
            notificationCenter: notificationCenter,
            timeProvider: FixedReminderTimeProvider(now: now)
        )

        let session = GoalSession(
            targetAppTokenData: Data("com.example.reddit".utf8),
            templateId: nil,
            goalTextSnapshot: "5분만 확인",
            startedAt: now,
            endedAt: nil,
            status: .active,
            plannedDurationMinutes: 15
        )

        try await repository.save(session)
        let schedule = try await scheduler.scheduleReminder(session: session, reminderOffsetMinutes: 5)

        let fired = try await scheduler.markReminderFired(reminderEventId: schedule.event.id)
        XCTAssertEqual(fired.firedAt, now)

        let acted = try await scheduler.markReminderAction(
            reminderEventId: schedule.event.id,
            action: .completed
        )
        XCTAssertEqual(acted.action, .completed)
        XCTAssertEqual(acted.firedAt, now)
    }
}

private struct FixedReminderTimeProvider: TimeProviderProtocol {
    let now: Date
}

private actor ReminderStore {
    var sessions: [UUID: GoalSession] = [:]
    var reminderEventsBySession: [UUID: [ReminderEvent]] = [:]
}

private final class InMemoryReminderRepository: GoalSessionRepository {
    private let store = ReminderStore()

    func fetchAll() async throws -> [GoalSession] {
        await store.sessions.values.sorted(by: { $0.startedAt < $1.startedAt })
    }

    func fetch(id: UUID) async throws -> GoalSession? {
        await store.sessions[id]
    }

    func fetch(from startDate: Date, to endDate: Date) async throws -> [GoalSession] {
        await store.sessions.values.filter { $0.startedAt >= startDate && $0.startedAt <= endDate }
    }

    func save(_ session: GoalSession) async throws {
        await store.sessions.updateValue(session, forKey: session.id)
    }

    func delete(id: UUID) async throws {
        await store.sessions.removeValue(forKey: id)
        await store.reminderEventsBySession.removeValue(forKey: id)
    }

    func saveReminderEvent(_ event: ReminderEvent) async throws {
        var events = await store.reminderEventsBySession[event.sessionId] ?? []

        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
        } else {
            events.append(event)
        }

        await store.reminderEventsBySession.updateValue(events, forKey: event.sessionId)
    }

    func fetchReminderEvents(sessionId: UUID) async throws -> [ReminderEvent] {
        await store.reminderEventsBySession[sessionId] ?? []
    }

    func fetchReminderEvent(id: UUID) async throws -> ReminderEvent? {
        let values = await store.reminderEventsBySession.values
        return values
            .flatMap { $0 }
            .first(where: { $0.id == id })
    }
}

private final class NotificationCenterSpy: UserNotificationCenterScheduling {
    private(set) var requests: [UNNotificationRequest] = []

    func add(_ request: UNNotificationRequest) async throws {
        requests.append(request)
    }
}
