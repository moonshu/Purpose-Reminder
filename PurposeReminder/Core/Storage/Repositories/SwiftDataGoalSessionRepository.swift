import Foundation
import SwiftData

final class SwiftDataGoalSessionRepository: GoalSessionRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() async throws -> [GoalSession] {
        let descriptor = FetchDescriptor<GoalSessionEntity>()
        return try context.fetch(descriptor).map(GoalSession.init(entity:))
    }

    func fetch(id: UUID) async throws -> GoalSession? {
        var descriptor = FetchDescriptor<GoalSessionEntity>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first.map(GoalSession.init(entity:))
    }

    func fetch(from startDate: Date, to endDate: Date) async throws -> [GoalSession] {
        let descriptor = FetchDescriptor<GoalSessionEntity>(
            predicate: #Predicate { $0.startedAt >= startDate && $0.startedAt <= endDate }
        )
        return try context.fetch(descriptor).map(GoalSession.init(entity:))
    }

    func save(_ session: GoalSession) async throws {
        if let existing = try findSessionEntity(id: session.id) {
            existing.apply(model: session)
        } else {
            context.insert(GoalSessionEntity(model: session))
        }
        try context.save()
    }

    func delete(id: UUID) async throws {
        let reminderDescriptor = FetchDescriptor<ReminderEventEntity>(
            predicate: #Predicate { $0.sessionId == id }
        )
        let reminders = try context.fetch(reminderDescriptor)
        reminders.forEach { context.delete($0) }

        if let existing = try findSessionEntity(id: id) {
            context.delete(existing)
        }
        try context.save()
    }

    func saveReminderEvent(_ event: ReminderEvent) async throws {
        if let existing = try findReminderEntity(id: event.id) {
            existing.apply(model: event)
        } else {
            context.insert(ReminderEventEntity(model: event))
        }
        try context.save()
    }

    func fetchReminderEvents(sessionId: UUID) async throws -> [ReminderEvent] {
        let descriptor = FetchDescriptor<ReminderEventEntity>(
            predicate: #Predicate { $0.sessionId == sessionId }
        )
        return try context.fetch(descriptor).map(ReminderEvent.init(entity:))
    }

    func fetchReminderEvent(id: UUID) async throws -> ReminderEvent? {
        var descriptor = FetchDescriptor<ReminderEventEntity>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first.map(ReminderEvent.init(entity:))
    }

    private func findSessionEntity(id: UUID) throws -> GoalSessionEntity? {
        var descriptor = FetchDescriptor<GoalSessionEntity>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func findReminderEntity(id: UUID) throws -> ReminderEventEntity? {
        var descriptor = FetchDescriptor<ReminderEventEntity>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
