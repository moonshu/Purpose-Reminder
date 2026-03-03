import Foundation

enum Constants {
    enum Session {
        static let defaultDurationMinutes: Int = 20
        static let defaultReminderOffsetMinutes: Int = 5
        static let extensionDurationMinutes: Int = 10
    }

    enum Notification {
        static let reminderCategoryIdentifier = "PURPOSE_REMINDER"
        static let reminderActionIdentifier = "OPEN_SESSION"
    }
}
