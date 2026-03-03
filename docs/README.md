# Purpose Reminder Docs Index

## 제품 기준 문서
- `ios-mvp-spec.md`: 제품 범위/사용자 플로우/데이터 모델 기준
- `onboarding-permission-ux-guide.md`: 랜딩/온보딩/권한 UX 개선 기준

## 구현 실행 문서
- `ios-technical-architecture.md`: 코드 구조/모듈 책임/테스트 전략
- `ios-dependencies-and-integrations.md`: 라이브러리/의존성/외부 연동 정리
- `ios-mvp-execution-roadmap.md`: 단계별 개발 계획과 완료 기준
- `ios-manual-setup-checklist.md`: 로그인/API 키/서명 등 수동 작업 체크리스트

## 에이전트 실행 문서
- `agent-ticket-spec.md`: 에이전트가 바로 실행 가능한 티켓 규격
- `agent-mvp-ticket-backlog.md`: MVP용 실제 에이전트 티켓 백로그

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

## 문서 동기화 규칙 (추가)
1. 티켓 완료 시 backlog 먼저 갱신
2. 아키텍처/의존성/체크리스트 동시 갱신
3. 변경 없음일 때도 근거 기록

## 사람 개입 필요 창구 (추가)
- 단일 기준: ios-manual-setup-checklist.md
- 중단 기록: agent-ticket-spec.md의 BLOCKED_MANUAL 포맷
