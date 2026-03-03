# PR-AG-016 계획 — ShieldRoute 소비 및 앱 라우팅 연결

## 0. 목적
- ShieldActionExtension이 App Group에 남긴 `shield.lastEvent`를 Main App이 안정적으로 소비해 `SessionStartView`로 이동시킨다.

## 1. 현재 코드베이스 진단
- 기록 측 구현 완료: `Extensions/ShieldActionExtension/ShieldActionExtension.swift`
- 소비 측 미구현: App Router에서 App Group route 이벤트를 읽지 않음

## 2. 범위
### In Scope
1. Shield route 이벤트 모델/디코딩 타입 추가
2. App Group route consume-once 서비스 구현
3. AppRouter route 반응(세션 탭 진입) 연결
4. 소비 서비스 테스트 추가

### Out of Scope
- app/application token까지 포함한 고급 라우팅

## 3. 변경 대상 파일
- `PurposeReminder/Core/Services/ScreenTime/ShieldRouteInboxService.swift` (신규)
- `PurposeReminder/App/AppRouter.swift`
- `PurposeReminderTests/ShieldRouteInboxServiceTests.swift` (신규)

## 4. 구현 전략
1. `ShieldRouteEvent` 모델을 Main App 측으로 재정의
2. consume API: 성공 시 `shield.lastEvent` 즉시 삭제(중복 방지)
3. AppRouter에서 `.task` 또는 lifecycle hook으로 route polling
4. `startGoalSelection`이면 SessionStart 탭 선택, `dismissShield`는 무시

## 5. 검증 명령
- `xcodebuild -project PurposeReminder.xcodeproj -scheme PurposeReminder -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' test -only-testing:PurposeReminderTests/ShieldRouteInboxServiceTests`

## 6. 완료 기준 (DoD)
- route 이벤트 1회 소비 후 재실행 시 재소비되지 않음
- `startGoalSelection` route 발생 시 메인 앱이 세션 시작 탭으로 이동

## 7. BLOCKED_MANUAL 조건
- `BM-016-01`: App Group 미설정으로 route 이벤트 공유 불가

## 8. 산출물
- Route inbox 서비스 코드
- 라우팅 테스트
