import Foundation

/// 빠른 목표 추천이 어떤 우선순위 소스에서 뽑혔는지 표시한다.
enum QuickGoalRecommendationSource: String, Equatable {
    case favorite
    case recentForTargetApp
    case recentGlobal
    case appDefault
}

struct QuickGoalRecommendation: Identifiable, Equatable {
    let template: GoalTemplate
    let source: QuickGoalRecommendationSource

    var id: UUID { template.id }
}

struct QuickGoalRecommendationResult: Equatable {
    let recommendations: [QuickGoalRecommendation]
    /// MVP 규칙: 새 목표 입력은 항상 하단 보조 옵션으로 노출
    let shouldShowCustomGoalInput: Bool
}

protocol QuickGoalRecommendationServicing {
    func recommend(
        templates: [GoalTemplate],
        targetAppTokenData: Data?,
        defaultTemplateId: UUID?
    ) -> QuickGoalRecommendationResult
}

struct QuickGoalRecommendationService: QuickGoalRecommendationServicing {
    func recommend(
        templates: [GoalTemplate],
        targetAppTokenData: Data?,
        defaultTemplateId: UUID?
    ) -> QuickGoalRecommendationResult {
        var ordered: [QuickGoalRecommendation] = []
        var seenTemplateIds: Set<UUID> = []

        let favorites = sortByRecencyAndUsage(
            templates.filter(\.isFavorite)
        )

        let targetAppRecent = sortByRecencyAndUsage(
            templates.filter { template in
                guard let targetAppTokenData else {
                    return false
                }
                return template.targetAppTokenData == targetAppTokenData && template.lastUsedAt != nil
            }
        )

        let globalRecent = sortByRecencyAndUsage(
            templates.filter { $0.lastUsedAt != nil }
        )

        appendUnique(
            templates: favorites,
            source: .favorite,
            to: &ordered,
            seenTemplateIds: &seenTemplateIds
        )

        appendUnique(
            templates: targetAppRecent,
            source: .recentForTargetApp,
            to: &ordered,
            seenTemplateIds: &seenTemplateIds
        )

        appendUnique(
            templates: globalRecent,
            source: .recentGlobal,
            to: &ordered,
            seenTemplateIds: &seenTemplateIds
        )

        if let defaultTemplateId,
           let defaultTemplate = templates.first(where: { $0.id == defaultTemplateId }) {
            appendUnique(
                templates: [defaultTemplate],
                source: .appDefault,
                to: &ordered,
                seenTemplateIds: &seenTemplateIds
            )
        }

        return QuickGoalRecommendationResult(
            recommendations: ordered,
            shouldShowCustomGoalInput: true
        )
    }

    private func appendUnique(
        templates: [GoalTemplate],
        source: QuickGoalRecommendationSource,
        to ordered: inout [QuickGoalRecommendation],
        seenTemplateIds: inout Set<UUID>
    ) {
        for template in templates where seenTemplateIds.insert(template.id).inserted {
            ordered.append(
                QuickGoalRecommendation(template: template, source: source)
            )
        }
    }

    private func sortByRecencyAndUsage(_ templates: [GoalTemplate]) -> [GoalTemplate] {
        templates.sorted { lhs, rhs in
            switch (lhs.lastUsedAt, rhs.lastUsedAt) {
            case let (lhsDate?, rhsDate?) where lhsDate != rhsDate:
                return lhsDate > rhsDate
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            default:
                break
            }

            if lhs.useCount != rhs.useCount {
                return lhs.useCount > rhs.useCount
            }

            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt > rhs.createdAt
            }

            return lhs.id.uuidString < rhs.id.uuidString
        }
    }
}
