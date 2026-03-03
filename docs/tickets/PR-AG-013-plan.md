# PR-AG-013 계획 — 핵심 E2E 시나리오 테스트 스크립트화

## 0. 목적
- MVP 핵심 플로우를 반복 실행 가능한 E2E 체크리스트로 표준화한다.
- QA/개발이 같은 실패 기준과 증적 포맷을 사용하도록 고정한다.

## 1. 현재 코드베이스 진단

### 이미 구현됨
- 온보딩 권한 플로우: `OnboardingView`, `AuthorizationService`
- 정책 저장 플로우: `PolicySettingsViewModel`, `ShieldPolicyService`
- 세션/리마인드 엔진: `SessionCoordinator`, `ReminderScheduler`
- Shield 액션 이벤트 기록: `ShieldActionExtension` (`shield.lastEvent`)

### 현재 갭
- E2E 실행 문서 부재(`docs/e2e-mvp-checklist.md` 없음)
- 시나리오별 사전조건/실패 기준/증적 규칙이 분산 문서에 흩어져 있음
- BLOCKED_MANUAL 전환 기준이 테스트 문맥에서 통일되지 않음

## 2. 범위

### In Scope
1. E2E 체크리스트 문서 신규 작성
2. 핵심 시나리오 6개 + Edge Case 표준화
3. 실행 결과 기록 템플릿 포함
4. BM 코드 매핑 포함

### Out of Scope
- UI 테스트 자동화 코드(XCUITest) 전체 작성
- TestFlight 배포 운영 문서까지 확장

## 3. 변경 대상 파일
- `docs/e2e-mvp-checklist.md` (신규)
- `docs/README.md` (E2E 문서 링크 추가)

## 4. 문서 설계

### 4-1. 필수 시나리오
1. 온보딩 권한 획득
2. 대상 앱 정책 저장
3. Shield 개입 후 세션 시작
4. 리마인드 수신 및 세션 종료 액션
5. 기록 화면 확인
6. App Intents 실행 확인

### 4-2. 시나리오 서식(고정)
- 사전 조건
- 실행 환경(실기기/시뮬레이터)
- 단계별 행동/기대 결과
- 실패 기준
- 증적 항목(스크린샷/로그)
- 실패 시 BM 코드

### 4-3. Edge Case 포함 항목
- Screen Time 권한 거부
- 알림 권한 거부
- 정책 없음 상태
- 즐겨찾기 없음 Intent 실행
- App Group 미설정 폴백

### 4-4. 결과 기록 템플릿
- 실행 일시
- 기기/OS
- 시나리오 ID
- Pass/Fail
- 증적 경로
- BM 코드(필요 시)

## 5. 검증 명령
- 문서 정합성 체크: `rg -n "E2E-|EE-|BM-013" docs/e2e-mvp-checklist.md`
- 링크 점검: `rg -n "e2e-mvp-checklist.md" docs/README.md docs/agent-mvp-ticket-backlog.md`

## 6. 완료 기준 (DoD)
- `docs/e2e-mvp-checklist.md` 생성
- 핵심 6시나리오 + Edge Case 목록 포함
- 각 시나리오에 실패 기준/증적 규칙 명시
- BM 전환 코드/조건이 문서 내에서 추적 가능

## 7. BLOCKED_MANUAL 조건
- `BM-013-01`: 실기기 접근 불가
- `BM-013-02`: FamilyControls/Signing 설정 미완료

## 8. 산출물
- E2E 체크리스트 문서
- 실행 결과 기록 템플릿 포함 문서
