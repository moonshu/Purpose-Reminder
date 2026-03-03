# Purpose Reminder iOS MVP Execution Roadmap

## 1. 목적
- `docs/ios-mvp-spec.md`를 실제 개발 일정/작업 단위로 분해한 실행 로드맵.
- 각 단계마다 완료 기준(Definition of Done)을 명확히 한다.

## 2. 전체 단계
1. Stage 0: 프로젝트 부트스트랩
2. Stage 1: 권한/정책/Shield 골격
3. Stage 2: 목표 선택 + 세션 엔진
4. Stage 3: 기록/단축어/QA

## 3. Stage 0 (2~3일) - 부트스트랩
### 작업
- Xcode 프로젝트/타겟 구성 (Main + 3 Extensions)
- 기본 폴더 구조 생성
- SwiftData 컨테이너 연결
- 공통 모델/Repository 인터페이스 초안

### 코드로 해결
- 앱 골격 코드, DI 기본 구성

### 수동 작업
- Apple Developer 로그인
- Bundle ID 생성
- Team/Signing 설정

### 완료 기준
- 앱/Extension 타겟 모두 빌드 성공
- 기본 화면 진입 가능

## 4. Stage 1 (4~5일) - 권한/정책/Shield
### 작업
- 온보딩 화면(권한 안내 + 요청)
- 대상 앱 선택(FamilyControls)
- AppPolicy 저장/수정 UI
- Shield Configuration/Action 기본 동작

### 코드로 해결
- 권한 상태 체크
- 정책 CRUD
- Shield 표시/액션 라우팅

### 수동 작업
- Screen Time 관련 Capability/Entitlement 설정 확인
- 실기기에서 권한 승인 플로우 검증

### 완료 기준
- 대상 앱 1개 이상 등록 가능
- 등록 앱 진입 시 Shield 개입 확인

## 5. Stage 2 (5~6일) - 목표 선택 + 세션 엔진
### 작업
- 빠른 목표(즐겨찾기/최근/기본) UI
- 새 목표 입력 UI
- SessionCoordinator 구현 (start/complete/extend/abandon/timed_out)
- 리마인드 예약/발송

### 코드로 해결
- 추천 정렬 우선순위 로직
- 상태 머신 기반 세션 전이
- ReminderEvent 기록

### 수동 작업
- 알림 권한 허용 상태 실기기 검증
- 종료/연장 시나리오 수동 테스트

### 완료 기준
- 목표 선택 후 세션 시작 가능
- 리마인드 수신 및 종료 액션 처리 가능

## 6. Stage 3 (4~5일) - 기록/단축어/QA
### 작업
- 기록 화면(오늘 요약 + 최근 세션)
- App Intents 2종 구현
- 핵심 시나리오 회귀 테스트
- 크래시/엣지 케이스 정리

### 코드로 해결
- 기록 집계 쿼리
- Intent 파라미터/실행 흐름

### 수동 작업
- Shortcuts 앱에서 Intent 동작 확인
- TestFlight 배포용 서명/버전 설정

### 완료 기준
- MVP 핵심 플로우 E2E 동작
- 내부 테스트 배포 가능 상태

## 7. 병렬 진행 가이드
1. Track A (앱/정책)
- 온보딩, 정책 화면, SwiftData

2. Track B (Shield/Extension)
- Shield 확장 구현, 정책 연결

3. Track C (세션/기록)
- SessionCoordinator, Reminder, 기록 집계

## 8. 리스크 게이트 (중간 점검)
1. Gate 1 (Stage 1 종료)
- Shield 개입이 불안정하면 나머지 작업 중단하고 안정화 우선

2. Gate 2 (Stage 2 종료)
- 세션 상태 전이 오류가 있으면 기록/단축어 작업 착수 금지

## 9. 최종 산출물
- 동작 앱(내부 배포 가능)
- 기술 문서 4종
  - MVP 스펙
  - 기술 아키텍처
  - 의존성/통합 문서
  - 수동 작업 체크리스트
