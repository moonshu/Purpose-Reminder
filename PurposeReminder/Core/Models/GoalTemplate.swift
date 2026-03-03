import Foundation

/// 목표 템플릿 — 빠른 시작 목록의 기본 단위
struct GoalTemplate: Identifiable, Codable, Equatable {
    let id: UUID
    /// 특정 앱용 템플릿이면 해당 앱 토큰, nil이면 공용 템플릿
    var targetAppTokenData: Data?
    var text: String
    var isFavorite: Bool
    var useCount: Int
    var lastUsedAt: Date?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        targetAppTokenData: Data? = nil,
        text: String,
        isFavorite: Bool = false,
        useCount: Int = 0,
        lastUsedAt: Date? = nil,
        createdAt: Date = Date()
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
