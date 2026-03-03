import Foundation

/// 리마인드 알림에 대한 사용자 반응 열거형
enum ReminderAction: String, Codable, CaseIterable {
    case ignored
    case opened
    case completed
    case extended
}

/// 리마인드 이벤트 기록
struct ReminderEvent: Identifiable, Codable, Equatable {
    let id: UUID
    var sessionId: UUID
    var scheduledAt: Date
    var firedAt: Date?
    var action: ReminderAction?

    init(
        id: UUID = UUID(),
        sessionId: UUID,
        scheduledAt: Date,
        firedAt: Date? = nil,
        action: ReminderAction? = nil
    ) {
        self.id = id
        self.sessionId = sessionId
        self.scheduledAt = scheduledAt
        self.firedAt = firedAt
        self.action = action
    }
}
