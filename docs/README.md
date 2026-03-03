# Purpose Reminder Docs Index

## 제품 기준 문서
- `ios-mvp-spec.md`: 제품 범위/사용자 플로우/데이터 모델 기준
- `onboarding-permission-ux-guide.md`: 랜딩/온보딩/권한 리디자인 에이전트 실행 플레이북

## 구현 실행 문서
- `ios-technical-architecture.md`: 코드 구조/모듈 책임/테스트 전략
- `ios-dependencies-and-integrations.md`: 라이브러리/의존성/외부 연동 정리
- `ios-mvp-execution-roadmap.md`: 단계별 개발 계획과 완료 기준
- `ios-stage4-execution-roadmap.md`: Stage 4(폐루프 완성) 실행 계획
- `ios-manual-setup-checklist.md`: 로그인/API 키/서명 등 수동 작업 체크리스트
- `e2e-mvp-checklist.md`: MVP 핵심 플로우 E2E 시나리오/증적 템플릿

## 에이전트 실행 문서
- `agent-ticket-spec.md`: 에이전트가 바로 실행 가능한 티켓 규격
- `agent-mvp-ticket-backlog.md`: MVP용 실제 에이전트 티켓 백로그
- `agent-stage4-ticket-backlog.md`: Stage 4 확장 티켓 백로그

## 권장 사용 순서
1. `ios-mvp-spec.md` 읽고 기능 범위 고정
2. `ios-technical-architecture.md`로 코드 구조 합의
3. `ios-dependencies-and-integrations.md`로 의존성 확정
4. `agent-ticket-spec.md`로 티켓 형식 고정
5. `agent-mvp-ticket-backlog.md`에서 READY 티켓 실행
6. 매 배포 전 `ios-manual-setup-checklist.md` 점검

## 티켓별 상세 계획 문서 (PR-AG-010~015)
- tickets/PR-AG-010-plan.md
- tickets/PR-AG-011-plan.md
- tickets/PR-AG-012-plan.md
- tickets/PR-AG-013-plan.md
- tickets/PR-AG-014-plan.md
- tickets/PR-AG-015-plan.md

## 티켓별 상세 계획 문서 (PR-AG-016~020)
- tickets/PR-AG-016-plan.md
- tickets/PR-AG-017-plan.md
- tickets/PR-AG-018-plan.md
- tickets/PR-AG-019-plan.md
- tickets/PR-AG-020-plan.md

## 문서 동기화 규칙

### Source of Truth 우선순위
1. 제품 범위/정책: `ios-mvp-spec.md`
2. 구현 구조: `ios-technical-architecture.md`
3. 실행 단위: `agent-mvp-ticket-backlog.md`
4. 수동 개입/운영: `ios-manual-setup-checklist.md`

### 변경 영역별 필수 갱신 문서
| 변경 영역 | 필수 갱신 문서 |
|---|---|
| `Core/Models`, `Core/Storage` | `ios-technical-architecture.md`, 관련 티켓 계획 문서 |
| `Core/Services/ScreenTime`, `Extensions` | `ios-dependencies-and-integrations.md`, `ios-manual-setup-checklist.md` |
| `Core/Services/Session` | `ios-technical-architecture.md`, `e2e-mvp-checklist.md` |
| `Core/Services/Shortcuts` | `ios-dependencies-and-integrations.md`, `e2e-mvp-checklist.md` |
| `Features/*` | `ios-mvp-spec.md`(화면/플로우 변경 시), `agent-mvp-ticket-backlog.md` |
| `docs/tickets/*` | `agent-mvp-ticket-backlog.md` 상세 계획 링크 |

### 완료 보고 최소 항목
1. 티켓 ID / 변경 파일
2. 실행한 검증 명령과 결과
3. 수동 검증 항목 번호 또는 BM 코드
4. 문서 갱신 목록 또는 `변경 없음 + 근거`

## 사람 개입 필요 창구

### 단일 진입점
- `ios-manual-setup-checklist.md`의 `00. 수동 개입 전체 요약`에서 시작

### 빠른 동선
1. BM 코드 확인: 체크리스트 §00 매핑표
2. 표준 기록 포맷: `agent-ticket-spec.md` §8
3. 해소 후 재개: 체크리스트 §00의 `BLOCKED -> READY` 절차
