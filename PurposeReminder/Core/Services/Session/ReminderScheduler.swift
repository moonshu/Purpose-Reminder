import Foundation
import UserNotifications

enum ReminderSchedulerError: LocalizedError, Equatable {
    case sessionNotFound
    case reminderEventNotFound

    var errorDescription: String? {
        switch self {
        case .sessionNotFound:
            return "리마인드 대상을 찾을 수 없습니다."
        case .reminderEventNotFound:
            return "리마인드 이벤트를 찾을 수 없습니다."
        }
    }
}

struct ReminderScheduleResult: Equatable {
    let event: ReminderEvent
    let requestIdentifier: String
}

protocol ReminderScheduling {
    func scheduleReminder(
        session: GoalSession,
        reminderOffsetMinutes: Int
    ) async throws -> ReminderScheduleResult
}

protocol UserNotificationCenterScheduling {
    func add(_ request: UNNotificationRequest) async throws
}

extension UNUserNotificationCenter: UserNotificationCenterScheduling {}

@MainActor
final class ReminderScheduler {
    private let repository: GoalSessionRepository
    private let notificationCenter: UserNotificationCenterScheduling
    private let timeProvider: TimeProviderProtocol

    init(
        repository: GoalSessionRepository,
        notificationCenter: UserNotificationCenterScheduling = UNUserNotificationCenter.current(),
        timeProvider: TimeProviderProtocol = SystemTimeProvider()
    ) {
        self.repository = repository
        self.notificationCenter = notificationCenter
        self.timeProvider = timeProvider
    }

    func scheduleReminder(
        sessionId: UUID,
        reminderOffsetMinutes: Int
    ) async throws -> ReminderScheduleResult {
        guard let session = try await repository.fetch(id: sessionId) else {
            throw ReminderSchedulerError.sessionNotFound
        }

        return try await scheduleReminder(
            session: session,
            reminderOffsetMinutes: reminderOffsetMinutes
        )
    }

    func scheduleReminder(
        session: GoalSession,
        reminderOffsetMinutes: Int
    ) async throws -> ReminderScheduleResult {
        let scheduledAt = reminderDate(
            session: session,
            reminderOffsetMinutes: reminderOffsetMinutes
        )

        let event = ReminderEvent(
            sessionId: session.id,
            scheduledAt: scheduledAt,
            firedAt: nil,
            action: nil
        )

        let requestIdentifier = "reminder-\(event.id.uuidString)"
        let content = UNMutableNotificationContent()
        content.title = "목표를 확인해 주세요"
        content.body = "세션 종료가 곧 다가옵니다."
        content.sound = .default
        content.categoryIdentifier = Constants.Notification.reminderCategoryIdentifier
        content.userInfo = [
            Constants.Notification.sessionIdUserInfoKey: session.id.uuidString,
            Constants.Notification.reminderEventIdUserInfoKey: event.id.uuidString
        ]

        let interval = max(1, scheduledAt.timeIntervalSince(timeProvider.now))
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: interval,
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: requestIdentifier,
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
        try await repository.saveReminderEvent(event)

        return ReminderScheduleResult(
            event: event,
            requestIdentifier: requestIdentifier
        )
    }

    func markReminderFired(reminderEventId: UUID) async throws -> ReminderEvent {
        let event = try await findReminderEvent(id: reminderEventId)
        var updated = event
        updated.firedAt = timeProvider.now
        try await repository.saveReminderEvent(updated)
        return updated
    }

    func markReminderAction(
        reminderEventId: UUID,
        action: ReminderAction
    ) async throws -> ReminderEvent {
        let event = try await findReminderEvent(id: reminderEventId)
        var updated = event
        updated.action = action
        if updated.firedAt == nil {
            updated.firedAt = timeProvider.now
        }
        try await repository.saveReminderEvent(updated)
        return updated
    }

    func reminderDate(
        session: GoalSession,
        reminderOffsetMinutes: Int
    ) -> Date {
        let effectiveOffset = max(0, reminderOffsetMinutes)
        let effectiveMinutes = max(0, session.plannedDurationMinutes - effectiveOffset)
        let seconds = max(1, effectiveMinutes * 60)
        return session.startedAt.addingTimeInterval(TimeInterval(seconds))
    }

    private func findReminderEvent(id: UUID) async throws -> ReminderEvent {
        if let event = try await repository.fetchReminderEvent(id: id) {
            return event
        }
        throw ReminderSchedulerError.reminderEventNotFound
    }
}

extension ReminderScheduler: ReminderScheduling {}
