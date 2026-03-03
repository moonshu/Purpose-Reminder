# Purpose Reminder iOS Stage 4 Execution Roadmap

## 1. 목적
- Stage 3 완료 이후 남아 있는 핵심 구현 갭을 닫아 "실사용 가능한 폐루프"를 완성한다.
- 대상: Shield 개입 -> 목표 선택 -> 세션 진행 -> 종료/타임아웃 -> 기록 반영 -> 단축어/알림 재진입.

## 2. 현재 기준선 (2026-03-04)

### 완료된 기반
- `SessionCoordinator`, `ReminderScheduler`, `HistoryView`, App Intents 2종, E2E 체크리스트 초안

### 미구현/부분구현
- `Features/GoalTemplates/GoalTemplatesView.swift` 플레이스홀더
- `Features/SessionActive/SessionActiveView.swift` 플레이스홀더
- `Extensions/DeviceActivityMonitorExtension/DeviceActivityMonitorExtension.swift` 플레이스홀더
- Shield 이벤트(`shield.lastEvent`)를 Main App이 소비하는 라우팅 경로 없음
- 알림 카테고리/액션 처리 파이프라인 미연결

## 3. Stage 4 범위
1. Shield -> Main App 목표 시작 라우팅 연결
2. 세션 진행/종료 UX(SessionActive) 완성
3. 목표 템플릿 CRUD 및 정책 기본 템플릿 연결
4. DeviceActivity 기반 타임아웃 자동 처리
5. 알림 액션(열기/완료/연장) 이벤트 파이프라인 연결

## 4. 티켓 구성
- `PR-AG-016`: ShieldRoute 소비 서비스 + AppRouter 라우팅 연결
- `PR-AG-017`: SessionActive 화면/뷰모델 + complete/extend/abandon 액션 연결
- `PR-AG-018`: GoalTemplates 화면/뷰모델 + Policy 기본 템플릿 연결
- `PR-AG-019`: DeviceActivityMonitorExtension 구현 + timed_out 기록
- `PR-AG-020`: Notification 카테고리/액션 처리 + ReminderEvent 업데이트

세부 계획: `docs/agent-stage4-ticket-backlog.md`, `docs/tickets/PR-AG-016~020-plan.md`

## 5. 병렬 트랙
- Track A (App UX): `PR-AG-017`, `PR-AG-018`
- Track B (Extension/Bridge): `PR-AG-016`, `PR-AG-019`
- Track C (Notification Lifecycle): `PR-AG-020`

## 6. Gate 기준
- Gate S4-1: Shield primary 액션 이후 3초 내 SessionStart 진입
- Gate S4-2: SessionActive 종료 액션 3종이 모두 기록 반영
- Gate S4-3: Timeout 자동 전환이 기록 화면에 반영
- Gate S4-4: 알림 액션 수행 시 ReminderEvent.action 정확히 반영

## 7. Stage 4 완료 기준 (DoD)
1. 플레이스홀더 3개(GoalTemplates/SessionActive/DeviceActivityMonitor) 제거
2. Stage 4 신규 테스트 8개 이상 통과
3. 실기기 수동 검증 항목 번호 기록
4. 문서 동기화(README, backlog, checklist, e2e) 완료

## 8. BLOCKED_MANUAL 운영
- 실기기/Signing/Capability 이슈는 BM 코드로 즉시 기록 후 해당 티켓만 `BLOCKED_MANUAL` 전환
- 다른 READY 티켓은 병렬 진행
