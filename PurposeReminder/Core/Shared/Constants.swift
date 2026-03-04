import Foundation

enum Constants {
    enum AppGroup {
        static let suiteName = "group.com.purposereminder.shared"
        static let shieldLastEventKey = "shield.lastEvent"
        static let timeoutLastEventKey = "session.timeout.lastEvent"
    }

    enum Session {
        static let defaultDurationMinutes: Int = 20
        static let defaultReminderOffsetMinutes: Int = 5
        static let extensionDurationMinutes: Int = 10
    }

    enum Notification {
        static let reminderCategoryIdentifier = "PURPOSE_REMINDER"
        static let openSessionActionIdentifier = "OPEN_SESSION"
        static let completeSessionActionIdentifier = "COMPLETE_SESSION"
        static let extendSessionActionIdentifier = "EXTEND_SESSION"

        static let sessionIdUserInfoKey = "sessionId"
        static let reminderEventIdUserInfoKey = "reminderEventId"

        // Backward compatibility for older call sites.
        static let reminderActionIdentifier = openSessionActionIdentifier
    }
}
