import SwiftUI
import UIKit
import UserNotifications

@main
struct PurposeReminderApp: App {
    @UIApplicationDelegateAdaptor(PurposeReminderAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            AppRouter()
        }
    }
}

final class PurposeReminderAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    private let notificationActionHandler = NotificationActionHandler()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        notificationActionHandler.registerCategories(center: center)
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task {
            await notificationActionHandler.handle(response: response)
            completionHandler()
        }
    }
}
