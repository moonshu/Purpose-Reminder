# PR-AG-010 계획 — 리마인드 스케줄링 구현

## 0. 목적
- 세션 시작 시 종료 N분 전 알림을 자동 예약하고, 알림 이벤트(`ReminderEvent`)를 일관되게 기록한다.
- 이미 구현된 `ReminderScheduler`를 실제 사용자 플로우(`SessionStart`)에 연결해 MVP 동작을 완성한다.

## 1. 현재 코드베이스 진단

### 이미 구현됨
- `ReminderScheduler` 기본 기능 존재
  - 파일: `PurposeReminder/Core/Services/Session/ReminderScheduler.swift`
  - 기능: 알림 예약(`scheduleReminder`), 이벤트 저장, fired/action 마킹
- 저장소 계층 준비 완료
  - 파일: `PurposeReminder/Core/Storage/Repositories/GoalSessionRepository.swift`
  - 기능: `saveReminderEvent`, `fetchReminderEvents`, `fetchReminderEvent`
- 단위 테스트 존재
  - 파일: `PurposeReminderTests/ReminderSchedulerTests.swift`

### 현재 갭
- 세션 시작 UI에서 리마인드 예약 호출이 빠져 있음
  - 파일: `PurposeReminder/Features/SessionStart/SessionStartRecommendationViewModel.swift`
- 중복 예약/재예약 정책이 명시되지 않음
- 알림 권한 거부 시 동작(저장은 하되 예약 실패 처리 등)이 정책화되지 않음

## 2. 범위

### In Scope
1. 세션 시작 성공 직후 리마인드 자동 예약 연결
2. 예약 성공/실패 시 사용자 피드백 정책 정리
3. 리마인드 이벤트 기록 일관성 보장
4. 자동 테스트 보강(연결 지점 포함)

### Out of Scope
- 알림 탭 액션의 딥링크 라우팅(UI 복귀/특정 화면 이동)
- 리마인드 재알림(반복 알림) 정책

## 3. 변경 대상 파일
- `PurposeReminder/Features/SessionStart/SessionStartRecommendationViewModel.swift`
- `PurposeReminder/Core/Services/Session/ReminderScheduler.swift` (필요 시 에러/중복 처리 보강)
- `PurposeReminderTests/ReminderSchedulerTests.swift`
- `PurposeReminderTests/SessionStartRecommendationViewModelTests.swift` (신규)

## 4. 구현 전략

### 4-1. 세션 시작과 리마인드 예약의 트랜잭션 경계 정의
- 기준: `GoalSession` 생성 성공이 우선이다.
- 정책:
  - 세션 저장 성공 + 알림 예약 성공: 정상 완료
  - 세션 저장 성공 + 알림 예약 실패: 세션은 유지, 경고 메시지만 노출
- 이유: 알림 실패로 세션 자체가 롤백되면 사용자 경험이 더 나빠짐

### 4-2. ViewModel 연동
- `SessionStartRecommendationViewModel.startSession(...)` 내부에 `ReminderScheduler` 의존성 주입
- 세션 생성 후 `selectedPolicy.reminderOffsetMinutes`로 예약 호출
- 에러 메시지 분리
  - 세션 실패: 기존 치명 오류 메시지
  - 리마인드 실패: 비치명 경고 메시지

### 4-3. 중복 예약 정책(명시)
- 동일 `sessionId`에 대해서는 리마인드 이벤트 1개만 활성 상태를 기본으로 둔다.
- 구현 옵션:
  1. 단순 정책: 세션당 1회만 예약(재호출 금지)
  2. 재예약 정책: 기존 이벤트를 취소 후 재생성
- MVP 권장: 옵션 1(복잡도 최소화)

### 4-4. 테스트 전략
- `ReminderSchedulerTests` 보강
  - 오프셋 경계값(0, duration-1, duration 초과)
  - 없는 세션 ID 처리
- `SessionStartRecommendationViewModelTests` 신규
  - 세션 시작 시 예약 호출됨
  - 예약 실패 시 세션은 생성되고 경고 메시지만 표시됨

## 5. 검증 명령
- 빌드: `xcodebuild -project PurposeReminder.xcodeproj -scheme PurposeReminder -destination 'platform=iOS Simulator,name=iPhone 16' build`
- 테스트: `xcodebuild -project PurposeReminder.xcodeproj -scheme PurposeReminder -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:PurposeReminderTests/ReminderSchedulerTests`
- 테스트(신규): `xcodebuild -project PurposeReminder.xcodeproj -scheme PurposeReminder -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:PurposeReminderTests/SessionStartRecommendationViewModelTests`

## 6. 완료 기준 (DoD)
- 세션 시작 경로에서 리마인드 예약이 자동 호출된다.
- 리마인드 예약 실패가 세션 생성 실패로 전파되지 않는다.
- 관련 테스트 최소 2개 이상 추가/통과 또는 불가 사유 기록
- 수동 검증 항목(알림 권한/수신) 체크리스트 번호 기록

## 7. BLOCKED_MANUAL 조건
- `BM-010-01`: 실기기 알림 권한 승인/수신 검증 불가

## 8. 산출물
- 세션 시작-리마인드 연결 코드
- 테스트 코드(스케줄러/뷰모델)
- 수동 검증 결과 기록(체크리스트 번호 포함)
