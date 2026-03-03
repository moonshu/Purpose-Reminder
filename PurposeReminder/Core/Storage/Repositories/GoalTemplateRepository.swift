import Foundation

/// GoalTemplate CRUD 및 조회 인터페이스
protocol GoalTemplateRepository {
    /// 모든 템플릿을 반환한다
    func fetchAll() async throws -> [GoalTemplate]
    /// 특정 앱 토큰 연결 템플릿을 반환한다 (nil이면 공용 템플릿)
    func fetch(forAppToken appTokenData: Data?) async throws -> [GoalTemplate]
    /// 즐겨찾기 템플릿만 반환한다
    func fetchFavorites() async throws -> [GoalTemplate]
    /// 템플릿을 저장(신규 삽입 또는 갱신)한다
    func save(_ template: GoalTemplate) async throws
    /// id에 해당하는 템플릿을 삭제한다
    func delete(id: UUID) async throws
}
