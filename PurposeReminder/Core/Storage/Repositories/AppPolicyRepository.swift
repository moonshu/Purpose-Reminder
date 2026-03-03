import Foundation

/// AppPolicy CRUD 인터페이스
protocol AppPolicyRepository {
    /// 저장된 모든 정책을 반환한다
    func fetchAll() async throws -> [AppPolicy]
    /// id로 특정 정책을 반환한다
    func fetch(id: UUID) async throws -> AppPolicy?
    /// 정책을 저장(신규 삽입 또는 갱신)한다
    func save(_ policy: AppPolicy) async throws
    /// id에 해당하는 정책을 삭제한다
    func delete(id: UUID) async throws
}
