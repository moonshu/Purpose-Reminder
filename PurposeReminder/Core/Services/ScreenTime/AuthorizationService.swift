import Foundation
import FamilyControls
import OSLog
import UserNotifications

enum ScreenTimePermissionStatus: Equatable {
    case approved
    case denied
    case notDetermined
}

enum NotificationPermissionStatus: Equatable {
    case authorized
    case denied
    case notDetermined
}

struct ScreenTimeAuthorizationRequestResult: Equatable {
    let status: ScreenTimePermissionStatus
    let errorDescription: String?
}

struct AuthorizationSnapshot: Equatable {
    let screenTime: ScreenTimePermissionStatus
    let notifications: NotificationPermissionStatus

    var isReadyForMainFlow: Bool {
        screenTime == .approved && notifications == .authorized
    }
}

@MainActor
protocol AuthorizationServicing {
    func fetchCurrentStatus() async -> AuthorizationSnapshot
    func requestScreenTimeAuthorization() async -> ScreenTimeAuthorizationRequestResult
    func requestNotificationAuthorization() async -> NotificationPermissionStatus
}

@MainActor
final class AuthorizationService: AuthorizationServicing {
    private let notificationCenter: UNUserNotificationCenter

    init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
    }

    func fetchCurrentStatus() async -> AuthorizationSnapshot {
        let screenTimeStatus = mapScreenTimeStatus(AuthorizationCenter.shared.authorizationStatus)
        let notificationStatus = await currentNotificationStatus()

        return AuthorizationSnapshot(
            screenTime: screenTimeStatus,
            notifications: notificationStatus
        )
    }

    func requestScreenTimeAuthorization() async -> ScreenTimeAuthorizationRequestResult {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            return ScreenTimeAuthorizationRequestResult(
                status: mapScreenTimeStatus(AuthorizationCenter.shared.authorizationStatus),
                errorDescription: nil
            )
        } catch {
            let message = Self.screenTimeAuthorizationErrorMessage(error)
            AppLogger.screenTime.error("Screen Time authorization request failed: \(message, privacy: .public)")
            return ScreenTimeAuthorizationRequestResult(
                status: mapScreenTimeStatus(AuthorizationCenter.shared.authorizationStatus),
                errorDescription: message
            )
        }
    }

    func requestNotificationAuthorization() async -> NotificationPermissionStatus {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                return .authorized
            }
        } catch {
            // Fallback to settings-based status if request fails.
        }

        return await currentNotificationStatus()
    }

    private func currentNotificationStatus() async -> NotificationPermissionStatus {
        await withCheckedContinuation { continuation in
            notificationCenter.getNotificationSettings { settings in
                continuation.resume(returning: Self.mapNotificationStatus(settings.authorizationStatus))
            }
        }
    }

    private func mapScreenTimeStatus(_ status: AuthorizationStatus) -> ScreenTimePermissionStatus {
        switch status {
        case .approved:
            return .approved
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }

    nonisolated private static func mapNotificationStatus(_ status: UNAuthorizationStatus) -> NotificationPermissionStatus {
        switch status {
        case .authorized, .provisional, .ephemeral:
            return .authorized
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }

    private static func screenTimeAuthorizationErrorMessage(_ error: Error) -> String {
        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription,
           !description.isEmpty {
            return description
        }

        let fallback = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        return fallback.isEmpty ? "Unknown Screen Time authorization error." : fallback
    }
}
