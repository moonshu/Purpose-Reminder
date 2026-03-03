import Foundation
import SwiftData
import OSLog

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

		do {
			let configuration = ModelConfiguration(
				isStoredInMemoryOnly: inMemory
			)
			container = try ModelContainer(for: schema, configurations: [configuration])
			mainContext = ModelContext(container)
		} catch {
			// Fallback for local/dev runtime issues (e.g. corrupted store path).
			// Keeps the app bootable while still surfacing the root cause.
			do {
				let fallback = ModelConfiguration(isStoredInMemoryOnly: true)
				container = try ModelContainer(for: schema, configurations: [fallback])
				mainContext = ModelContext(container)
				AppLogger.storage.warning("SwiftData persistent store init failed. Fallback to in-memory store. error=\(String(describing: error))")
			} catch {
				fatalError("Failed to initialize SwiftData container (persistent + inMemory fallback): \(error)")
			}
		}
	}
}
