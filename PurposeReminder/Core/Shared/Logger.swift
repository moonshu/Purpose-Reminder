import Foundation
import OSLog

struct AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.purposereminder"

    static let session = Logger(subsystem: subsystem, category: "Session")
    static let storage = Logger(subsystem: subsystem, category: "Storage")
    static let screenTime = Logger(subsystem: subsystem, category: "ScreenTime")
    static let reminder = Logger(subsystem: subsystem, category: "Reminder")
    static let onboarding = Logger(subsystem: subsystem, category: "Onboarding")
}
