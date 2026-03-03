# PR-AG-012 계획 — App Intents 2종 구현

## 0. 목적
- Shortcuts에서 바로 세션을 시작할 수 있도록 App Intent 2종을 구현한다.
- Intent 자체는 얇게 유지하고, 실제 비즈니스 로직은 재사용 가능한 서비스로 분리한다.

## 1. 현재 코드베이스 진단

### 이미 구현됨
- 세션 시작 핵심 엔진: `SessionCoordinator`
- 정책/템플릿 저장소: `SwiftDataAppPolicyRepository`, `SwiftDataGoalTemplateRepository`
- 단축어 브릿지 파일 존재: `Core/Services/Shortcuts/AppIntentBridge.swift` (플레이스홀더)
- 즐겨찾기 조회 API 존재: `GoalTemplateRepository.fetchFavorites()`

### 현재 갭
- App Intent 타입 부재(`QuickStartIntent`, `FavoriteStartIntent`)
- Intent 등록자(`AppShortcutsProvider`) 부재
- Intent 동작 테스트 전략 부재
- 수동 검증(실기기 Shortcuts 노출) 문서화만 있고 실행 루프 없음

## 2. 범위

### In Scope
1. Intent 2종 구현
2. Intent에서 사용할 공통 실행 서비스 추출
3. Intent 노출 등록(`AppShortcutsProvider`)
4. 단위 테스트 추가(서비스 중심)

### Out of Scope
- Siri 음성 문구 최적화/다국어 고도화
- 홈 화면 위젯/액션 버튼 통합

## 3. 변경 대상 파일
- `PurposeReminder/Core/Services/Shortcuts/AppIntentBridge.swift`
- `PurposeReminder/Core/Services/Shortcuts/QuickStartIntent.swift` (신규)
- `PurposeReminder/Core/Services/Shortcuts/FavoriteStartIntent.swift` (신규)
- `PurposeReminder/Core/Services/Shortcuts/IntentSessionStarter.swift` (신규, 공통 서비스)
- `PurposeReminderTests/IntentSessionStarterTests.swift` (신규)

## 4. 구현 전략

### 4-1. Intent 정의
- `QuickStartIntent`
  - 입력: `goalText`, `durationMinutes`
  - 정책: 활성 정책이 없으면 사용자 안내 dialog 반환
- `FavoriteStartIntent`
  - 입력 없음
  - 정책: 즐겨찾기 템플릿 + 활성 정책이 모두 있어야 시작

### 4-2. 공통 서비스 분리 (`IntentSessionStarter`)
- 역할: 정책/템플릿 조회 + `SessionCoordinator.beginGoalSelection/startSession` 실행
- 장점: Intent 프레임워크 의존 없이 테스트 가능
- 반환: 성공(세션 요약 메시지) / 실패(사용자 안내 메시지)

### 4-3. Intent 등록
- `AppIntentBridge.swift`에서 `AppShortcutsProvider` 구현
- Shortcuts 리스트에 두 Intent 노출
- 앱명 문구/짧은 타이틀/아이콘 설정

### 4-4. 오류 처리 정책
- throw를 사용자에게 그대로 노출하지 않음
- 예상 가능한 도메인 오류는 안내 문구로 변환
  - 활성 정책 없음
  - 즐겨찾기 없음
  - 진행 중 세션 존재

### 4-5. 테스트 전략
- 서비스 단위 테스트로 핵심 경로 검증
  - 정책 없음
  - 즐겨찾기 없음
  - 정상 시작 시 세션 저장 확인
  - 진행 중 세션에서 재시작 차단

## 5. 검증 명령
- 빌드: `xcodebuild -project PurposeReminder.xcodeproj -scheme PurposeReminder -destination 'platform=iOS Simulator,name=iPhone 16' build`
- 테스트: `xcodebuild -project PurposeReminder.xcodeproj -scheme PurposeReminder -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:PurposeReminderTests/IntentSessionStarterTests`

## 6. 완료 기준 (DoD)
- Intent 2종 컴파일/등록 완료
- 서비스 테스트 최소 4개 이상 통과
- 수동: 실기기 Shortcuts 앱에서 두 Intent 노출 및 1회 실행 확인
- 체크리스트 항목 번호로 수동 결과 기록

## 7. BLOCKED_MANUAL 조건
- `BM-012-01`: 실기기 Shortcuts 노출/실행 검증 불가
- `BM-012-02`: Signing/Capability 설정 누락으로 Intent 미노출

## 8. 산출물
- Intent 구현 코드 2종
- 공통 시작 서비스 및 테스트
- 수동 검증 기록
