import Foundation
import SwiftData

final class SwiftDataAppPolicyRepository: AppPolicyRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() async throws -> [AppPolicy] {
        let descriptor = FetchDescriptor<AppPolicyEntity>()
        let entities = try context.fetch(descriptor)
        return entities.map(AppPolicy.init(entity:))
    }

    func fetch(id: UUID) async throws -> AppPolicy? {
        var descriptor = FetchDescriptor<AppPolicyEntity>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first.map(AppPolicy.init(entity:))
    }

    func save(_ policy: AppPolicy) async throws {
        if let existing = try findEntity(id: policy.id) {
            existing.apply(model: policy)
        } else {
            context.insert(AppPolicyEntity(model: policy))
        }
        try context.save()
    }

    func delete(id: UUID) async throws {
        if let existing = try findEntity(id: id) {
            context.delete(existing)
            try context.save()
        }
    }

    private func findEntity(id: UUID) throws -> AppPolicyEntity? {
        var descriptor = FetchDescriptor<AppPolicyEntity>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
