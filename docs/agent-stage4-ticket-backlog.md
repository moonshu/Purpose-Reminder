# Purpose Reminder Agent Stage 4 Ticket Backlog

## 1. 사용 방법
- Stage 4는 Stage 3 이후 확장 단계다.
- 상태가 `READY`인 티켓만 실행한다.
- 실기기/Capability 이슈는 `BLOCKED_MANUAL`로 전환한다.

## 2. Stage 4

## [PR-AG-016] ShieldRoute 소비 및 앱 라우팅 연결
- 목표: ShieldActionExtension이 기록한 `shield.lastEvent`를 Main App이 소비해 SessionStart로 라우팅
- 선행 조건: PR-AG-006, PR-AG-009
- 입력 문서: `docs/ios-stage4-execution-roadmap.md`
- 변경 대상: `App/AppRouter.swift`, `Core/Services/ScreenTime/*`
- 산출물: ShieldRouteInboxService + 라우팅 테스트
- 실행 단계:
1. App Group 이벤트 읽기/소비 서비스 구현
2. AppRouter에 route 처리 파이프라인 추가
- 검증: route 소비 테스트 + 메인 라우팅 동작 확인
- 완료 기준: `startGoalSelection` 이벤트 1회 소비 후 SessionStart 진입
- 중단 조건 (사람 개입 필요): App Group 미설정
- 수동 작업: 실기기에서 Shield primary 탭 동작 확인

## [PR-AG-017] SessionActive 화면 및 종료 액션 구현
- 목표: active 세션 진행 화면에서 완료/연장/중단 액션 처리
- 선행 조건: PR-AG-008, PR-AG-010
- 입력 문서: `docs/ios-stage4-execution-roadmap.md`
- 변경 대상: `Features/SessionActive`, `Core/Services/Session`
- 산출물: SessionActiveView + ViewModel + 테스트
- 실행 단계:
1. active 세션 조회/카운트다운 구현
2. 종료 액션 3종(SessionCoordinator 연동) 구현
- 검증: ViewModel 테스트(완료/연장/중단)
- 완료 기준: 액션 수행 후 GoalSession.status 정확히 반영
- 중단 조건 (사람 개입 필요): 없음
- 수동 작업: 실기기에서 세션 종료 UX 확인

## [PR-AG-018] GoalTemplates 화면 및 정책 기본 템플릿 연결
- 목표: 템플릿 CRUD/즐겨찾기/기본 템플릿 지정 UX 구현
- 선행 조건: PR-AG-007, PR-AG-011
- 입력 문서: `docs/ios-stage4-execution-roadmap.md`
- 변경 대상: `Features/GoalTemplates`, `Features/PolicySettings`
- 산출물: GoalTemplatesView + Policy defaultTemplate 선택 UI
- 실행 단계:
1. 템플릿 목록/생성/수정/삭제 구현
2. PolicySettings에 defaultTemplate 연결
- 검증: Repository 연동 테스트 + 화면 렌더링 확인
- 완료 기준: defaultTemplateId가 정책에 저장/복원됨
- 중단 조건 (사람 개입 필요): 없음
- 수동 작업: 없음

## [PR-AG-019] DeviceActivityMonitorExtension 타임아웃 처리 구현
- 목표: DeviceActivity 모니터 이벤트로 세션 timed_out 전환 자동화
- 선행 조건: PR-AG-006, PR-AG-017
- 입력 문서: `docs/ios-stage4-execution-roadmap.md`
- 변경 대상: `Extensions/DeviceActivityMonitorExtension`, `Core/Services/Session`
- 산출물: Extension 구현 + timeout 브릿지 처리
- 실행 단계:
1. DeviceActivity 이벤트 수신 및 세션 식별
2. timed_out 상태 저장 및 기록 반영
- 검증: timeout 처리 테스트 + E2E 시나리오 보강
- 완료 기준: 시간 경과 시 자동으로 timed_out 기록
- 중단 조건 (사람 개입 필요): Capability/Entitlement 미설정
- 수동 작업: 실기기 DeviceActivity 동작 검증

## [PR-AG-020] 알림 액션 파이프라인 구현
- 목표: 리마인드 알림 액션(열기/완료/연장)을 ReminderEvent에 반영
- 선행 조건: PR-AG-010, PR-AG-017
- 입력 문서: `docs/ios-stage4-execution-roadmap.md`
- 변경 대상: `App/PurposeReminderApp.swift`, `Core/Services/Session`, `Core/Shared`
- 산출물: NotificationCategory 등록 + 응답 핸들러 + 테스트
- 실행 단계:
1. 알림 카테고리/액션 등록
2. 액션별 ReminderEvent.action 업데이트
- 검증: 핸들러 테스트 + 알림 userInfo 파싱 테스트
- 완료 기준: 액션별 `ignored/opened/completed/extended` 저장
- 중단 조건 (사람 개입 필요): 실기기 알림 액션 테스트 불가
- 수동 작업: 실기기 알림 액션 확인
