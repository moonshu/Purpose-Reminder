import Foundation
import SwiftData

@Model
final class AppPolicyEntity {
    @Attribute(.unique) var id: UUID
    var appTokenData: Data
    var isActive: Bool
    var defaultDurationMinutes: Int
    var reminderOffsetMinutes: Int
    var defaultTemplateId: UUID?

    init(
        id: UUID,
        appTokenData: Data,
        isActive: Bool,
        defaultDurationMinutes: Int,
        reminderOffsetMinutes: Int,
        defaultTemplateId: UUID?
    ) {
        self.id = id
        self.appTokenData = appTokenData
        self.isActive = isActive
        self.defaultDurationMinutes = defaultDurationMinutes
        self.reminderOffsetMinutes = reminderOffsetMinutes
        self.defaultTemplateId = defaultTemplateId
    }
}

@Model
final class GoalTemplateEntity {
    @Attribute(.unique) var id: UUID
    var targetAppTokenData: Data?
    var text: String
    var isFavorite: Bool
    var useCount: Int
    var lastUsedAt: Date?
    var createdAt: Date

    init(
        id: UUID,
        targetAppTokenData: Data?,
        text: String,
        isFavorite: Bool,
        useCount: Int,
        lastUsedAt: Date?,
        createdAt: Date
    ) {
        self.id = id
        self.targetAppTokenData = targetAppTokenData
        self.text = text
        self.isFavorite = isFavorite
        self.useCount = useCount
        self.lastUsedAt = lastUsedAt
        self.createdAt = createdAt
    }
}

@Model
final class GoalSessionEntity {
    @Attribute(.unique) var id: UUID
    var targetAppTokenData: Data
    var templateId: UUID?
    var goalTextSnapshot: String
    var startedAt: Date
    var endedAt: Date?
    var statusRaw: String
    var plannedDurationMinutes: Int

    init(
        id: UUID,
        targetAppTokenData: Data,
        templateId: UUID?,
        goalTextSnapshot: String,
        startedAt: Date,
        endedAt: Date?,
        statusRaw: String,
        plannedDurationMinutes: Int
    ) {
        self.id = id
        self.targetAppTokenData = targetAppTokenData
        self.templateId = templateId
        self.goalTextSnapshot = goalTextSnapshot
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.statusRaw = statusRaw
        self.plannedDurationMinutes = plannedDurationMinutes
    }
}

@Model
final class ReminderEventEntity {
    @Attribute(.unique) var id: UUID
    var sessionId: UUID
    var scheduledAt: Date
    var firedAt: Date?
    var actionRaw: String?

    init(
        id: UUID,
        sessionId: UUID,
        scheduledAt: Date,
        firedAt: Date?,
        actionRaw: String?
    ) {
        self.id = id
        self.sessionId = sessionId
        self.scheduledAt = scheduledAt
        self.firedAt = firedAt
        self.actionRaw = actionRaw
    }
}
