import Foundation
import SwiftData

@MainActor
final class SwiftDataStack {
	static let shared = SwiftDataStack()

	let container: ModelContainer
	let mainContext: ModelContext

	init(inMemory: Bool = false) {
		let schema = Schema([
			AppPolicyEntity.self,
			GoalTemplateEntity.self,
			GoalSessionEntity.self,
			ReminderEventEntity.self
		])

		let configuration = ModelConfiguration(
			isStoredInMemoryOnly: inMemory
		)

		do {
			container = try ModelContainer(for: schema, configurations: [configuration])
			mainContext = ModelContext(container)
		} catch {
			fatalError("Failed to initialize SwiftData container: \(error)")
		}
	}
}
