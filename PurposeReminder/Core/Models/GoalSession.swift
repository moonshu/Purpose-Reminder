import Foundation

/// 세션 상태 전이 열거형
/// 기본: idle → pending_goal → active → reminded → completed
/// 연장: active / reminded → extended
/// 중단: active / reminded → abandoned
/// 시간초과: active / reminded → timed_out
enum SessionStatus: String, Codable, CaseIterable {
    case active
    case completed
    case extended
    case abandoned
    case timedOut = "timed_out"
}

/// 목표 기반 앱 사용 세션 기록
struct GoalSession: Identifiable, Codable, Equatable {
    let id: UUID
    var targetAppTokenData: Data
    /// 템플릿을 사용한 경우 참조 ID
    var templateId: UUID?
    /// 세션 시작 시점의 목표 문구 스냅샷
    var goalTextSnapshot: String
    var startedAt: Date
    var endedAt: Date?
    var status: SessionStatus
    var plannedDurationMinutes: Int

    init(
        id: UUID = UUID(),
        targetAppTokenData: Data,
        templateId: UUID? = nil,
        goalTextSnapshot: String,
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        status: SessionStatus = .active,
        plannedDurationMinutes: Int = Constants.Session.defaultDurationMinutes
    ) {
        self.id = id
        self.targetAppTokenData = targetAppTokenData
        self.templateId = templateId
        self.goalTextSnapshot = goalTextSnapshot
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.status = status
        self.plannedDurationMinutes = plannedDurationMinutes
    }
}
