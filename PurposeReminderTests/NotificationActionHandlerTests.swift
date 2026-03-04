import XCTest
import UserNotifications
@testable import PurposeReminder

@MainActor
final class NotificationActionHandlerTests: XCTestCase {
    func testDefaultTapMapsToOpened() async {
        let marker = ReminderMarkerSpy()
        let performer = SessionActionPerformerSpy()
        let handler = NotificationActionHandler(
            reminderMarker: marker,
            sessionActionPerformer: performer
        )

        let reminderEventId = UUID()
        await handler.handle(
            actionIdentifier: UNNotificationDefaultActionIdentifier,
            userInfo: [Constants.Notification.reminderEventIdUserInfoKey: reminderEventId.uuidString]
        )

        XCTAssertEqual(marker.calls.first?.action, .opened)
        XCTAssertEqual(performer.completedSessionIds.count, 0)
        XCTAssertEqual(performer.extendedSessionIds.count, 0)
    }

    func testDismissMapsToIgnored() async {
        let marker = ReminderMarkerSpy()
        let performer = SessionActionPerformerSpy()
        let handler = NotificationActionHandler(
            reminderMarker: marker,
            sessionActionPerformer: performer
        )

        let reminderEventId = UUID()
        await handler.handle(
            actionIdentifier: UNNotificationDismissActionIdentifier,
            userInfo: [Constants.Notification.reminderEventIdUserInfoKey: reminderEventId.uuidString]
        )

        XCTAssertEqual(marker.calls.first?.action, .ignored)
        XCTAssertTrue(performer.completedSessionIds.isEmpty)
        XCTAssertTrue(performer.extendedSessionIds.isEmpty)
    }

    func testCompleteActionMarksAndCompletesSession() async {
        let marker = ReminderMarkerSpy()
        let performer = SessionActionPerformerSpy()
        let handler = NotificationActionHandler(
            reminderMarker: marker,
            sessionActionPerformer: performer
        )

        let reminderEventId = UUID()
        let sessionId = UUID()
        marker.nextEvent = ReminderEvent(id: reminderEventId, sessionId: sessionId, scheduledAt: Date())

        await handler.handle(
            actionIdentifier: Constants.Notification.completeSessionActionIdentifier,
            userInfo: [Constants.Notification.reminderEventIdUserInfoKey: reminderEventId.uuidString]
        )

        XCTAssertEqual(marker.calls.first?.action, .completed)
        XCTAssertEqual(performer.completedSessionIds, [sessionId])
        XCTAssertTrue(performer.extendedSessionIds.isEmpty)
    }

    func testExtendActionMarksAndExtendsSession() async {
        let marker = ReminderMarkerSpy()
        let performer = SessionActionPerformerSpy()
        let handler = NotificationActionHandler(
            reminderMarker: marker,
            sessionActionPerformer: performer
        )

        let reminderEventId = UUID()
        let sessionId = UUID()
        marker.nextEvent = ReminderEvent(id: reminderEventId, sessionId: sessionId, scheduledAt: Date())

        await handler.handle(
            actionIdentifier: Constants.Notification.extendSessionActionIdentifier,
            userInfo: [Constants.Notification.reminderEventIdUserInfoKey: reminderEventId.uuidString]
        )

        XCTAssertEqual(marker.calls.first?.action, .extended)
        XCTAssertEqual(performer.extendedSessionIds, [sessionId])
        XCTAssertTrue(performer.completedSessionIds.isEmpty)
    }

    func testMalformedUserInfoDoesNothing() async {
        let marker = ReminderMarkerSpy()
        let performer = SessionActionPerformerSpy()
        let handler = NotificationActionHandler(
            reminderMarker: marker,
            sessionActionPerformer: performer
        )

        await handler.handle(
            actionIdentifier: Constants.Notification.completeSessionActionIdentifier,
            userInfo: [:]
        )

        XCTAssertTrue(marker.calls.isEmpty)
        XCTAssertTrue(performer.completedSessionIds.isEmpty)
    }

    func testUnknownActionIsIgnoredSafely() async {
        let marker = ReminderMarkerSpy()
        let performer = SessionActionPerformerSpy()
        let handler = NotificationActionHandler(
            reminderMarker: marker,
            sessionActionPerformer: performer
        )

        await handler.handle(
            actionIdentifier: "UNKNOWN_ACTION",
            userInfo: [Constants.Notification.reminderEventIdUserInfoKey: UUID().uuidString]
        )

        XCTAssertTrue(marker.calls.isEmpty)
        XCTAssertTrue(performer.completedSessionIds.isEmpty)
        XCTAssertTrue(performer.extendedSessionIds.isEmpty)
    }
}

@MainActor
private final class ReminderMarkerSpy: ReminderEventActionMarking {
    struct Call {
        let reminderEventId: UUID
        let action: ReminderAction
    }

    var calls: [Call] = []
    var nextEvent = ReminderEvent(sessionId: UUID(), scheduledAt: Date())

    func markReminderAction(reminderEventId: UUID, action: ReminderAction) async throws -> ReminderEvent {
        calls.append(Call(reminderEventId: reminderEventId, action: action))
        var event = nextEvent
        event.action = action
        return event
    }
}

@MainActor
private final class SessionActionPerformerSpy: SessionNotificationActionPerforming {
    private(set) var attachedSessionIds: [UUID] = []
    private(set) var completedSessionIds: [UUID] = []
    private(set) var extendedSessionIds: [UUID] = []
    private var currentSessionId: UUID?

    func attachToActiveSessionIfNeeded(sessionId: UUID) async throws {
        attachedSessionIds.append(sessionId)
        currentSessionId = sessionId
    }

    func completeSession() async throws -> GoalSession {
        let sessionId = currentSessionId ?? UUID()
        completedSessionIds.append(sessionId)
        return GoalSession(
            id: sessionId,
            targetAppTokenData: Data(),
            templateId: nil,
            goalTextSnapshot: "complete",
            startedAt: Date(),
            endedAt: Date(),
            status: .completed,
            plannedDurationMinutes: 20
        )
    }

    func extendSession(by minutes: Int) async throws -> GoalSession {
        let sessionId = currentSessionId ?? UUID()
        extendedSessionIds.append(sessionId)
        return GoalSession(
            id: sessionId,
            targetAppTokenData: Data(),
            templateId: nil,
            goalTextSnapshot: "extend",
            startedAt: Date(),
            endedAt: Date(),
            status: .extended,
            plannedDurationMinutes: 20 + minutes
        )
    }
}
