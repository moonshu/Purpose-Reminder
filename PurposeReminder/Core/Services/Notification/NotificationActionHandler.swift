import Foundation
import OSLog
import UserNotifications

@MainActor
protocol NotificationActionHandling {
    func registerCategories(center: UNUserNotificationCenter)
    func handle(response: UNNotificationResponse) async
}

@MainActor
protocol ReminderEventActionMarking {
    func markReminderAction(
        reminderEventId: UUID,
        action: ReminderAction
    ) async throws -> ReminderEvent
}

extension ReminderScheduler: ReminderEventActionMarking {}

@MainActor
protocol SessionNotificationActionPerforming {
    func attachToActiveSessionIfNeeded(sessionId: UUID) async throws
    func completeSession() async throws -> GoalSession
    func extendSession(by minutes: Int) async throws -> GoalSession
}

extension SessionCoordinator: SessionNotificationActionPerforming {}

@MainActor
final class NotificationActionHandler: NotificationActionHandling {
    private let reminderMarker: ReminderEventActionMarking
    private let sessionActionPerformer: SessionNotificationActionPerforming

    init(
        reminderMarker: ReminderEventActionMarking,
        sessionActionPerformer: SessionNotificationActionPerforming
    ) {
        self.reminderMarker = reminderMarker
        self.sessionActionPerformer = sessionActionPerformer
    }

    convenience init() {
        let repository = SwiftDataGoalSessionRepository(context: SwiftDataStack.shared.mainContext)
        self.init(
            reminderMarker: ReminderScheduler(repository: repository),
            sessionActionPerformer: SessionCoordinator(repository: repository)
        )
    }

    func registerCategories(center: UNUserNotificationCenter = .current()) {
        let open = UNNotificationAction(
            identifier: Constants.Notification.openSessionActionIdentifier,
            title: "열기"
        )

        let complete = UNNotificationAction(
            identifier: Constants.Notification.completeSessionActionIdentifier,
            title: "완료"
        )

        let extend = UNNotificationAction(
            identifier: Constants.Notification.extendSessionActionIdentifier,
            title: "연장 \(Constants.Session.extensionDurationMinutes)분"
        )

        let category = UNNotificationCategory(
            identifier: Constants.Notification.reminderCategoryIdentifier,
            actions: [open, complete, extend],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([category])
    }

    func handle(response: UNNotificationResponse) async {
        await handle(
            actionIdentifier: response.actionIdentifier,
            userInfo: response.notification.request.content.userInfo
        )
    }

    func handle(
        actionIdentifier: String,
        userInfo: [AnyHashable: Any]
    ) async {
        guard let action = mapReminderAction(from: actionIdentifier),
              let reminderEventId = parseUUID(
                from: userInfo[Constants.Notification.reminderEventIdUserInfoKey]
              ) else {
            return
        }

        do {
            let event = try await reminderMarker.markReminderAction(
                reminderEventId: reminderEventId,
                action: action
            )
            try await applySessionActionIfNeeded(for: action, sessionId: event.sessionId)
        } catch {
            AppLogger.reminder.error("Failed to handle notification action: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func applySessionActionIfNeeded(
        for action: ReminderAction,
        sessionId: UUID
    ) async throws {
        switch action {
        case .completed:
            try await sessionActionPerformer.attachToActiveSessionIfNeeded(sessionId: sessionId)
            _ = try await sessionActionPerformer.completeSession()
        case .extended:
            try await sessionActionPerformer.attachToActiveSessionIfNeeded(sessionId: sessionId)
            _ = try await sessionActionPerformer.extendSession(by: Constants.Session.extensionDurationMinutes)
        case .opened, .ignored:
            break
        }
    }

    private func mapReminderAction(from actionIdentifier: String) -> ReminderAction? {
        switch actionIdentifier {
        case UNNotificationDefaultActionIdentifier,
             Constants.Notification.openSessionActionIdentifier:
            return .opened
        case UNNotificationDismissActionIdentifier:
            return .ignored
        case Constants.Notification.completeSessionActionIdentifier:
            return .completed
        case Constants.Notification.extendSessionActionIdentifier:
            return .extended
        default:
            return nil
        }
    }

    private func parseUUID(from rawValue: Any?) -> UUID? {
        if let stringValue = rawValue as? String {
            return UUID(uuidString: stringValue)
        }
        return nil
    }
}
