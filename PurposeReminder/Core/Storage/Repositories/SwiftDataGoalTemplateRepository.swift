import Foundation
import SwiftData

final class SwiftDataGoalTemplateRepository: GoalTemplateRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() async throws -> [GoalTemplate] {
        let descriptor = FetchDescriptor<GoalTemplateEntity>()
        return try context.fetch(descriptor).map(GoalTemplate.init(entity:))
    }

    func fetch(forAppToken appTokenData: Data?) async throws -> [GoalTemplate] {
        if let appTokenData {
            let descriptor = FetchDescriptor<GoalTemplateEntity>(
                predicate: #Predicate { $0.targetAppTokenData == appTokenData }
            )
            return try context.fetch(descriptor).map(GoalTemplate.init(entity:))
        }

        let descriptor = FetchDescriptor<GoalTemplateEntity>(
            predicate: #Predicate { $0.targetAppTokenData == nil }
        )
        return try context.fetch(descriptor).map(GoalTemplate.init(entity:))
    }

    func fetchFavorites() async throws -> [GoalTemplate] {
        let descriptor = FetchDescriptor<GoalTemplateEntity>(
            predicate: #Predicate { $0.isFavorite == true }
        )
        return try context.fetch(descriptor).map(GoalTemplate.init(entity:))
    }

    func save(_ template: GoalTemplate) async throws {
        if let existing = try findEntity(id: template.id) {
            existing.apply(model: template)
        } else {
            context.insert(GoalTemplateEntity(model: template))
        }
        try context.save()
    }

    func delete(id: UUID) async throws {
        if let existing = try findEntity(id: id) {
            context.delete(existing)
            try context.save()
        }
    }

    private func findEntity(id: UUID) throws -> GoalTemplateEntity? {
        var descriptor = FetchDescriptor<GoalTemplateEntity>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
