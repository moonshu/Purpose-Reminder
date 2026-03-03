# PR-AG-020 계획 — 알림 액션 파이프라인 구현

## 0. 목적
- 리마인드 알림의 사용자 액션(열기/완료/연장)을 `ReminderEvent.action`으로 일관되게 저장한다.

## 1. 현재 코드베이스 진단
- 알림 예약 시 category/userInfo 설정은 있음: `ReminderScheduler`
- 알림 카테고리 등록/응답 핸들러 미구현
- `markReminderAction` API는 존재하나 호출 경로 없음

## 2. 범위
### In Scope
1. 앱 시작 시 알림 카테고리/액션 등록
2. 알림 응답 핸들러(AppDelegate bridge) 구현
3. 액션별 ReminderEvent 업데이트
4. 파싱/핸들러 테스트 추가

### Out of Scope
- 리치 알림 커스텀 UI

## 3. 변경 대상 파일
- `PurposeReminder/App/PurposeReminderApp.swift`
- `PurposeReminder/Core/Services/Session/ReminderScheduler.swift` (필요 시 helper)
- `PurposeReminder/Core/Services/Notification/NotificationActionHandler.swift` (신규)
- `PurposeReminderTests/NotificationActionHandlerTests.swift` (신규)

## 4. 구현 전략
1. `UNNotificationCategory` 등록 (`OPEN_SESSION`, `COMPLETE_SESSION`, `EXTEND_SESSION`)
2. `UNUserNotificationCenterDelegate`에서 userInfo의 `reminderEventId` 파싱
3. 액션 ID를 `ReminderAction`으로 매핑해 `markReminderAction` 호출
4. 잘못된 payload는 무시하고 로그만 남김

## 5. 검증 명령
- `xcodebuild -project PurposeReminder.xcodeproj -scheme PurposeReminder -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' test -only-testing:PurposeReminderTests/NotificationActionHandlerTests`

## 6. 완료 기준 (DoD)
- 알림 액션 처리 후 ReminderEvent.action이 정확히 저장됨
- malformed payload에서도 앱이 크래시하지 않음

## 7. BLOCKED_MANUAL 조건
- `BM-020-01`: 실기기 알림 액션 수동 테스트 불가

## 8. 산출물
- Notification action 핸들러 코드
- 알림 액션 테스트
