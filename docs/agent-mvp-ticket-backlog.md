# Purpose Reminder Agent MVP Ticket Backlog

## 1. 사용 방법
- 아래 티켓은 `docs/ios-mvp-spec.md` 기준으로 작성된 에이전트 실행용 백로그다.
- 원칙: `READY` 상태 티켓만 실행한다.
- `BLOCKED_MANUAL`은 사람이 개입한 뒤 다시 `READY`로 바꾼다.

## 2. Stage 0
## [PR-AG-001] 프로젝트 기본 구조 생성
- 목표: Feature-first 폴더 구조와 기본 파일 골격 생성
- 선행 조건: 없음
- 입력 문서: `docs/ios-technical-architecture.md`
- 변경 대상: 프로젝트 소스 디렉터리
- 산출물: `App`, `Core`, `Features`, `Extensions`, `Tests` 기본 구조
- 실행 단계:
1. 디렉터리/기본 파일 생성
2. 최소 컴파일 가능한 App 엔트리 연결
- 검증: 프로젝트 파일에서 경로 누락 없는지 점검
- 완료 기준: 구조가 문서와 일치
- 중단 조건 (사람 개입 필요): 없음
- 수동 작업: 없음

## [PR-AG-002] 데이터 모델/리포지토리 인터페이스 추가
- 목표: AppPolicy, GoalTemplate, GoalSession, ReminderEvent 모델/인터페이스 정의
- 선행 조건: PR-AG-001
- 입력 문서: `docs/ios-mvp-spec.md`
- 변경 대상: `Core/Models`, `Core/Storage/Repositories`
- 산출물: 모델 타입 + CRUD 인터페이스
- 실행 단계:
1. 모델 타입 구현
2. Repository protocol 추가
- 검증: 타입 에러 없음
- 완료 기준: 모든 MVP 모델 필드 반영
- 중단 조건 (사람 개입 필요): 없음
- 수동 작업: 없음

## [PR-AG-003] SwiftData 저장 계층 구현
- 목표: Repository의 SwiftData 구현체 작성
- 선행 조건: PR-AG-002
- 입력 문서: `docs/ios-technical-architecture.md`
- 변경 대상: `Core/Storage`
- 산출물: SwiftDataStack + Repository 구현체
- 실행 단계:
1. SwiftData 컨테이너 구성
2. CRUD 구현
- 검증: 저장/조회 단위 테스트
- 완료 기준: 기본 CRUD 시나리오 통과
- 중단 조건 (사람 개입 필요): 없음
- 수동 작업: 없음

## 3. Stage 1
## [PR-AG-004] 온보딩 권한 화면 구현
- 목표: Screen Time/알림 권한 요청 온보딩 UI 및 로직 구현
- 선행 조건: PR-AG-001
- 입력 문서: `docs/ios-mvp-spec.md`
- 변경 대상: `Features/Onboarding`, `Core/Services/ScreenTime`
- 산출물: 온보딩 화면 + 권한 상태 표시
- 실행 단계:
1. 온보딩 View/ViewModel 작성
2. 권한 요청 서비스 연결
- 검증: 권한 상태별 화면 분기 확인
- 완료 기준: 권한 요청 흐름 동작
- 중단 조건 (사람 개입 필요): 실기기 승인 확인 단계
- 수동 작업: 실기기에서 권한 허용

## [PR-AG-005] 대상 앱 선택/정책 저장 구현
- 목표: FamilyControls 앱 선택 + AppPolicy CRUD 구현
- 선행 조건: PR-AG-003, PR-AG-004
- 입력 문서: `docs/ios-mvp-spec.md`
- 변경 대상: `Features/PolicySettings`, `Core/Services/ScreenTime`
- 산출물: 정책 설정 화면
- 실행 단계:
1. 앱 선택 UI 연결
2. 기본 시간/리마인드 저장
- 검증: 정책 저장 후 재진입 시 유지
- 완료 기준: 최소 1개 정책 생성 가능
- 중단 조건 (사람 개입 필요): FamilyControls 권한 승인 실패
- 수동 작업: 실기기 권한 허용

## [PR-AG-006] Shield Extension 골격 구현
- 목표: Shield Configuration/Action 기본 동작 연결
- 선행 조건: PR-AG-005
- 입력 문서: `docs/ios-technical-architecture.md`
- 변경 대상: `Extensions/ShieldConfigurationExtension`, `Extensions/ShieldActionExtension`
- 산출물: Shield 기본 UI + 액션 라우팅
- 실행 단계:
1. 확장 타겟 코드 작성
2. 정책과 연결
- 검증: 대상 앱 진입 시 개입 여부 확인
- 완료 기준: Shield 개입 이벤트 발생
- 중단 조건 (사람 개입 필요): Signing/Entitlement 미설정
- 수동 작업: Capability/Entitlement 설정

## 4. Stage 2
## [PR-AG-007] 빠른 목표 추천 로직 구현
- 목표: 즐겨찾기/최근/기본 목표 우선순위 정렬 로직 구현
- 선행 조건: PR-AG-002
- 입력 문서: `docs/ios-mvp-spec.md`
- 변경 대상: `Core/Services/Session`, `Features/SessionStart`
- 산출물: 추천 결과 함수 + 테스트
- 실행 단계:
1. 정렬 알고리즘 구현
2. 유닛 테스트 작성
- 검증: 우선순위 테스트 통과
- 완료 기준: 4단계 정렬 규칙 만족
- 중단 조건 (사람 개입 필요): 없음
- 수동 작업: 없음

## [PR-AG-008] 세션 시작/종료/연장 상태 머신 구현
- 목표: SessionCoordinator 상태 전이 구현
- 선행 조건: PR-AG-003
- 입력 문서: `docs/ios-mvp-spec.md`
- 변경 대상: `Core/Services/Session`
- 산출물: SessionCoordinator + 전이 테스트
- 실행 단계:
1. 상태 전이 로직 구현
2. active/completed/extended/abandoned/timed_out 테스트
- 검증: 상태 전이 유닛 테스트
- 완료 기준: 전이 규칙과 문서 일치
- 중단 조건 (사람 개입 필요): 없음
- 수동 작업: 없음

## [PR-AG-009] SessionStart 화면 구현
- 목표: 빠른 시작 목록 + 새 목표 입력 화면 구현
- 선행 조건: PR-AG-007, PR-AG-008
- 입력 문서: `docs/ios-mvp-spec.md`
- 변경 대상: `Features/SessionStart`
- 산출물: 세션 시작 UI
- 실행 단계:
1. 빠른 목표 리스트 렌더링
2. 입력 폼 + 시작 액션 연결
- 검증: 템플릿 탭 시 즉시 시작
- 완료 기준: 원탭 시작 동작
- 중단 조건 (사람 개입 필요): 없음
- 수동 작업: 없음

## [PR-AG-010] 리마인드 스케줄링 구현
- 목표: 종료 N분 전 알림 스케줄링 및 이벤트 기록
- 선행 조건: PR-AG-008
- 입력 문서: `docs/ios-mvp-spec.md`
- 변경 대상: `Core/Services/Session`, `Core/Storage`
- 산출물: ReminderScheduler + ReminderEvent 기록
- 실행 단계:
1. 로컬 알림 예약
2. 이벤트 저장
- 검증: 스케줄 계산 테스트
- 완료 기준: 리마인드 예약 로직 동작
- 중단 조건 (사람 개입 필요): 실기기 알림 권한 거부 상태
- 수동 작업: 알림 권한 허용

## 5. Stage 3
## [PR-AG-011] 기록 화면 구현
- 목표: 오늘 요약/최근 세션 조회 UI 구현
- 선행 조건: PR-AG-008
- 입력 문서: `docs/ios-mvp-spec.md`
- 변경 대상: `Features/History`
- 산출물: 기록 화면
- 실행 단계:
1. 집계 쿼리 구현
2. 리스트/요약 UI 구현
- 검증: 더미 데이터 기반 렌더링 확인
- 완료 기준: 완료율/연장/중단 지표 표시
- 중단 조건 (사람 개입 필요): 없음
- 수동 작업: 없음

## [PR-AG-012] App Intents 2종 구현
- 목표: 빠른 목표 시작/즐겨찾기 시작 Intent 구현
- 선행 조건: PR-AG-009
- 입력 문서: `docs/ios-mvp-spec.md`
- 변경 대상: `Core/Services/Shortcuts`
- 산출물: AppIntent 타입 2개
- 실행 단계:
1. Intent 정의
2. 세션 시작 로직 연동
- 검증: Intent 인보크 경로 테스트
- 완료 기준: 단축어에서 호출 가능
- 중단 조건 (사람 개입 필요): Shortcuts 앱 실기기 확인
- 수동 작업: 단축어 실행 검증

## [PR-AG-013] 핵심 E2E 시나리오 테스트 스크립트화
- 목표: MVP 핵심 플로우 점검 스크립트/체크리스트 작성
- 선행 조건: PR-AG-011, PR-AG-012
- 입력 문서: `docs/ios-mvp-execution-roadmap.md`
- 변경 대상: `docs` 또는 `Tests`
- 산출물: E2E 체크리스트 문서
- 실행 단계:
1. 시나리오 정의
2. 통과 기준 문서화
- 검증: 케이스 누락 점검
- 완료 기준: 내부 QA 재사용 가능
- 중단 조건 (사람 개입 필요): 실기기 실행
- 수동 작업: QA 수행

## 6. 운영 티켓
## [PR-AG-014] 문서 동기화 자동화 규칙 정리
- 목표: 구현 후 문서 업데이트 규칙 정리
- 선행 조건: 없음
- 입력 문서: 전체 docs
- 변경 대상: `docs/README.md`
- 산출물: 문서 업데이트 규칙
- 실행 단계:
1. 소스 오브 트루스 지정
2. 갱신 타이밍 정의
- 검증: 충돌 없는지 검토
- 완료 기준: 문서 드리프트 방지 규칙 확정
- 중단 조건 (사람 개입 필요): 없음
- 수동 작업: 없음

## [PR-AG-015] 수동 작업 창구 통합 문서화
- 목표: 사람이 해야 하는 작업만 한곳에서 보이게 정리
- 선행 조건: 없음
- 입력 문서: `docs/ios-manual-setup-checklist.md`
- 변경 대상: `docs/README.md`
- 산출물: "사람 개입 필요" 섹션 링크
- 실행 단계:
1. 문서 링크 정리
2. BLOCKED_MANUAL 처리 규칙 추가
- 검증: 온보딩 사용자가 바로 찾을 수 있는지 확인
- 완료 기준: 수동 작업 누락 위험 최소화
- 중단 조건 (사람 개입 필요): 없음
- 수동 작업: 없음
