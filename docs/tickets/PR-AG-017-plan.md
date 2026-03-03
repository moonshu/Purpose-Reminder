# PR-AG-017 계획 — SessionActive 화면 및 종료 액션 구현

## 0. 목적
- active 세션 진행 상태를 보여주고 완료/연장/중단 액션으로 세션 lifecycle을 닫는다.

## 1. 현재 코드베이스 진단
- 상태 전이 엔진 존재: `SessionCoordinator`
- UI 미구현: `Features/SessionActive/SessionActiveView.swift` 플레이스홀더
- 세션 종료 액션 UI 경로 부재

## 2. 범위
### In Scope
1. SessionActiveView + ViewModel 구현
2. active 세션 조회/카운트다운 렌더링
3. complete/extend/abandon 액션 처리
4. 액션 후 기록 화면 반영 경로 검증

### Out of Scope
- Live Activity/Widget 연동

## 3. 변경 대상 파일
- `PurposeReminder/Features/SessionActive/SessionActiveView.swift`
- `PurposeReminder/Features/SessionStart/SessionStartView.swift` (진입 동선)
- `PurposeReminderTests/SessionActiveViewModelTests.swift` (신규)

## 4. 구현 전략
1. ViewModel에서 `GoalSessionRepository`로 active 세션 로드
2. 세션 종료 액션은 `SessionCoordinator`를 통해 수행
3. 연장은 기본값 `Constants.Session.extensionDurationMinutes` 사용
4. 액션 성공 시 상태 메시지/재진입 제어

## 5. 검증 명령
- `xcodebuild -project PurposeReminder.xcodeproj -scheme PurposeReminder -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' test -only-testing:PurposeReminderTests/SessionActiveViewModelTests`

## 6. 완료 기준 (DoD)
- 완료/연장/중단 액션이 각 status로 정확히 저장됨
- UI에서 active 세션 시간/목표가 표시됨

## 7. BLOCKED_MANUAL 조건
- 없음

## 8. 산출물
- SessionActive 화면 코드
- 액션 테스트
