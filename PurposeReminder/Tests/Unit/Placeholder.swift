import XCTest

@MainActor
final class AppPolicyRepositoryTests: XCTestCase {
	func testAppPolicyCRUD() async throws {
		let stack = SwiftDataStack(inMemory: true)
		let repository = SwiftDataAppPolicyRepository(context: stack.mainContext)

		let policy = AppPolicy(
			appTokenData: Data("com.example.instagram".utf8),
			isActive: true,
			defaultDurationMinutes: 20,
			reminderOffsetMinutes: 5,
			defaultTemplateId: nil
		)

		try await repository.save(policy)

		let fetched = try await repository.fetch(id: policy.id)
		XCTAssertEqual(fetched, policy)

		var updated = policy
		updated.defaultDurationMinutes = 30
		try await repository.save(updated)

		let fetchedAll = try await repository.fetchAll()
		XCTAssertEqual(fetchedAll.count, 1)
		XCTAssertEqual(fetchedAll.first?.defaultDurationMinutes, 30)

		try await repository.delete(id: policy.id)
		let afterDelete = try await repository.fetchAll()
		XCTAssertTrue(afterDelete.isEmpty)
	}
}
