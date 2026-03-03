# PR-AG-019 계획 — DeviceActivityMonitorExtension 타임아웃 처리 구현

## 0. 목적
- DeviceActivity 이벤트를 사용해 세션 만료 시 `timed_out` 상태를 자동 기록한다.

## 1. 현재 코드베이스 진단
- Extension 파일 존재하나 구현 없음: `Extensions/DeviceActivityMonitorExtension/DeviceActivityMonitorExtension.swift`
- SessionCoordinator에 `timeoutSession()`은 존재하나 자동 트리거 연결 부재

## 2. 범위
### In Scope
1. DeviceActivityMonitorExtension 이벤트 핸들러 구현
2. 세션 식별/타임아웃 브릿지 구조 추가
3. timed_out 저장/기록 반영 경로 연결
4. 통합 테스트 또는 시뮬레이션 테스트 추가

### Out of Scope
- 다중 세션 병렬 타임아웃 정책 고도화

## 3. 변경 대상 파일
- `PurposeReminder/Extensions/DeviceActivityMonitorExtension/DeviceActivityMonitorExtension.swift`
- `PurposeReminder/Core/Services/Session/*` (timeout bridge)
- `PurposeReminderTests/SessionTimeoutFlowTests.swift` (신규)

## 4. 구현 전략
1. DeviceActivity 이벤트 수신 시 app group/event bus에 timeout 이벤트 기록
2. Main App에서 timeout 이벤트 소비 후 `timeoutSession()` 실행
3. 타임아웃 중복 반영 방지(idempotent) 처리

## 5. 검증 명령
- `xcodebuild -project PurposeReminder.xcodeproj -scheme PurposeReminder -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' test -only-testing:PurposeReminderTests/SessionTimeoutFlowTests`

## 6. 완료 기준 (DoD)
- 시간 만료 시 GoalSession.status가 `timed_out`으로 저장됨
- 기록 화면에 타임아웃 집계 반영

## 7. BLOCKED_MANUAL 조건
- `BM-019-01`: DeviceActivity capability/실기기 검증 불가

## 8. 산출물
- DeviceActivity monitor 구현 코드
- timeout 통합 테스트
