import DeviceActivity
import Foundation
import OSLog

private struct TimeoutPayload: Codable {
    let activityName: String
    let reason: String
    let occurredAt: TimeInterval
}

final class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    private let logger = Logger(
        subsystem: "com.purposereminder.app",
        category: "DeviceActivityMonitorExtension"
    )

    override func intervalDidEnd(for activity: DeviceActivityName) {
        recordTimeoutEvent(activityName: activity.rawValue, reason: "intervalDidEnd")
    }

    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        recordTimeoutEvent(
            activityName: activity.rawValue,
            reason: "eventDidReachThreshold:\(event.rawValue)"
        )
    }

    private func recordTimeoutEvent(activityName: String, reason: String) {
        guard let defaults = UserDefaults(suiteName: Constants.AppGroup.suiteName) else {
            logger.error("App Group UserDefaults unavailable for timeout event.")
            return
        }

        let payload = TimeoutPayload(
            activityName: activityName,
            reason: reason,
            occurredAt: Date().timeIntervalSince1970
        )

        do {
            let data = try JSONEncoder().encode(payload)
            defaults.set(data, forKey: Constants.AppGroup.timeoutLastEventKey)
        } catch {
            logger.error("Failed to encode timeout event: \(error.localizedDescription, privacy: .public)")
        }
    }
}
