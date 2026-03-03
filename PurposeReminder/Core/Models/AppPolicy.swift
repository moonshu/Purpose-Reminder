import Foundation

/// 앱 사용 정책 — 대상 앱별 기본 시간/리마인드/기본 템플릿 설정
struct AppPolicy: Identifiable, Codable, Equatable {
    let id: UUID
    /// FamilyControls ApplicationToken의 인코딩된 Data 표현
    var appTokenData: Data
    var isActive: Bool
    var defaultDurationMinutes: Int
    var reminderOffsetMinutes: Int
    var defaultTemplateId: UUID?

    init(
        id: UUID = UUID(),
        appTokenData: Data,
        isActive: Bool = true,
        defaultDurationMinutes: Int = Constants.Session.defaultDurationMinutes,
        reminderOffsetMinutes: Int = Constants.Session.defaultReminderOffsetMinutes,
        defaultTemplateId: UUID? = nil
    ) {
        self.id = id
        self.appTokenData = appTokenData
        self.isActive = isActive
        self.defaultDurationMinutes = defaultDurationMinutes
        self.reminderOffsetMinutes = reminderOffsetMinutes
        self.defaultTemplateId = defaultTemplateId
    }
}
