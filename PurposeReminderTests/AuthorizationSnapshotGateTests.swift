import XCTest
@testable import PurposeReminder

final class AuthorizationSnapshotGateTests: XCTestCase {
    func testMainFlowRequiresOnlyScreenTimePermission() {
        let approvedButNotificationDenied = AuthorizationSnapshot(
            screenTime: .approved,
            notifications: .denied
        )
        XCTAssertTrue(approvedButNotificationDenied.hasRequiredPermissions)
        XCTAssertTrue(approvedButNotificationDenied.isReadyForMainFlow)

        let notificationGrantedOnly = AuthorizationSnapshot(
            screenTime: .notDetermined,
            notifications: .authorized
        )
        XCTAssertFalse(notificationGrantedOnly.hasRequiredPermissions)
        XCTAssertFalse(notificationGrantedOnly.isReadyForMainFlow)
    }

    func testReminderAvailabilityUsesNotificationPermission() {
        let authorizedSnapshot = AuthorizationSnapshot(
            screenTime: .approved,
            notifications: .authorized
        )
        XCTAssertTrue(authorizedSnapshot.canDeliverReminders)

        let deniedSnapshot = AuthorizationSnapshot(
            screenTime: .approved,
            notifications: .denied
        )
        XCTAssertFalse(deniedSnapshot.canDeliverReminders)
    }
}
