import Foundation

/// GoalSession CRUD 및 조회 인터페이스
protocol GoalSessionRepository {
    /// 모든 세션을 반환한다
    func fetchAll() async throws -> [GoalSession]
    /// id로 특정 세션을 반환한다
    func fetch(id: UUID) async throws -> GoalSession?
    /// 특정 기간 내의 세션을 반환한다
    func fetch(from startDate: Date, to endDate: Date) async throws -> [GoalSession]
    /// 세션을 저장(신규 삽입 또는 갱신)한다
    func save(_ session: GoalSession) async throws
    /// id에 해당하는 세션을 삭제한다
    func delete(id: UUID) async throws

    // MARK: - ReminderEvent
    /// 세션에 연결된 리마인드 이벤트를 저장한다
    func saveReminderEvent(_ event: ReminderEvent) async throws
    /// 세션 ID로 리마인드 이벤트를 조회한다
    func fetchReminderEvents(sessionId: UUID) async throws -> [ReminderEvent]
    /// id로 특정 리마인드 이벤트를 조회한다
    func fetchReminderEvent(id: UUID) async throws -> ReminderEvent?
}
