import XCTest

@MainActor
final class GoalSessionRepositoryIntegrationTests: XCTestCase {
	func testGoalSessionAndReminderEventPersistence() async throws {
		let stack = SwiftDataStack(inMemory: true)
		let repository = SwiftDataGoalSessionRepository(context: stack.mainContext)

		let session = GoalSession(
			targetAppTokenData: Data("com.example.youtube".utf8),
			templateId: nil,
			goalTextSnapshot: "영상 1개만 확인",
			startedAt: Date(timeIntervalSince1970: 1_700_000_000),
			endedAt: nil,
			status: .active,
			plannedDurationMinutes: 20
		)

		try await repository.save(session)

		let reminder = ReminderEvent(
			sessionId: session.id,
			scheduledAt: Date(timeIntervalSince1970: 1_700_000_900),
			firedAt: nil,
			action: nil
		)
		try await repository.saveReminderEvent(reminder)

		let fetchedSession = try await repository.fetch(id: session.id)
		XCTAssertNotNil(fetchedSession)
		XCTAssertEqual(fetchedSession?.goalTextSnapshot, "영상 1개만 확인")

		let fetchedEvents = try await repository.fetchReminderEvents(sessionId: session.id)
		XCTAssertEqual(fetchedEvents.count, 1)
		XCTAssertEqual(fetchedEvents.first?.id, reminder.id)

		try await repository.delete(id: session.id)
		let eventsAfterSessionDelete = try await repository.fetchReminderEvents(sessionId: session.id)
		XCTAssertTrue(eventsAfterSessionDelete.isEmpty)
	}
}
