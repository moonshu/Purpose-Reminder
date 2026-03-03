import Foundation

extension AppPolicy {
    init(entity: AppPolicyEntity) {
        self.init(
            id: entity.id,
            appTokenData: entity.appTokenData,
            isActive: entity.isActive,
            defaultDurationMinutes: entity.defaultDurationMinutes,
            reminderOffsetMinutes: entity.reminderOffsetMinutes,
            defaultTemplateId: entity.defaultTemplateId
        )
    }
}

extension AppPolicyEntity {
    convenience init(model: AppPolicy) {
        self.init(
            id: model.id,
            appTokenData: model.appTokenData,
            isActive: model.isActive,
            defaultDurationMinutes: model.defaultDurationMinutes,
            reminderOffsetMinutes: model.reminderOffsetMinutes,
            defaultTemplateId: model.defaultTemplateId
        )
    }

    func apply(model: AppPolicy) {
        appTokenData = model.appTokenData
        isActive = model.isActive
        defaultDurationMinutes = model.defaultDurationMinutes
        reminderOffsetMinutes = model.reminderOffsetMinutes
        defaultTemplateId = model.defaultTemplateId
    }
}

extension GoalTemplate {
    init(entity: GoalTemplateEntity) {
        self.init(
            id: entity.id,
            targetAppTokenData: entity.targetAppTokenData,
            text: entity.text,
            isFavorite: entity.isFavorite,
            useCount: entity.useCount,
            lastUsedAt: entity.lastUsedAt,
            createdAt: entity.createdAt
        )
    }
}

extension GoalTemplateEntity {
    convenience init(model: GoalTemplate) {
        self.init(
            id: model.id,
            targetAppTokenData: model.targetAppTokenData,
            text: model.text,
            isFavorite: model.isFavorite,
            useCount: model.useCount,
            lastUsedAt: model.lastUsedAt,
            createdAt: model.createdAt
        )
    }

    func apply(model: GoalTemplate) {
        targetAppTokenData = model.targetAppTokenData
        text = model.text
        isFavorite = model.isFavorite
        useCount = model.useCount
        lastUsedAt = model.lastUsedAt
        createdAt = model.createdAt
    }
}

extension GoalSession {
    init(entity: GoalSessionEntity) {
        self.init(
            id: entity.id,
            targetAppTokenData: entity.targetAppTokenData,
            templateId: entity.templateId,
            goalTextSnapshot: entity.goalTextSnapshot,
            startedAt: entity.startedAt,
            endedAt: entity.endedAt,
            status: SessionStatus(rawValue: entity.statusRaw) ?? .active,
            plannedDurationMinutes: entity.plannedDurationMinutes
        )
    }
}

extension GoalSessionEntity {
    convenience init(model: GoalSession) {
        self.init(
            id: model.id,
            targetAppTokenData: model.targetAppTokenData,
            templateId: model.templateId,
            goalTextSnapshot: model.goalTextSnapshot,
            startedAt: model.startedAt,
            endedAt: model.endedAt,
            statusRaw: model.status.rawValue,
            plannedDurationMinutes: model.plannedDurationMinutes
        )
    }

    func apply(model: GoalSession) {
        targetAppTokenData = model.targetAppTokenData
        templateId = model.templateId
        goalTextSnapshot = model.goalTextSnapshot
        startedAt = model.startedAt
        endedAt = model.endedAt
        statusRaw = model.status.rawValue
        plannedDurationMinutes = model.plannedDurationMinutes
    }
}

extension ReminderEvent {
    init(entity: ReminderEventEntity) {
        self.init(
            id: entity.id,
            sessionId: entity.sessionId,
            scheduledAt: entity.scheduledAt,
            firedAt: entity.firedAt,
            action: entity.actionRaw.flatMap(ReminderAction.init(rawValue:))
        )
    }
}

extension ReminderEventEntity {
    convenience init(model: ReminderEvent) {
        self.init(
            id: model.id,
            sessionId: model.sessionId,
            scheduledAt: model.scheduledAt,
            firedAt: model.firedAt,
            actionRaw: model.action?.rawValue
        )
    }

    func apply(model: ReminderEvent) {
        sessionId = model.sessionId
        scheduledAt = model.scheduledAt
        firedAt = model.firedAt
        actionRaw = model.action?.rawValue
    }
}
