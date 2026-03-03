# Purpose Reminder iOS Dependencies & Integrations (MVP)

## 1. 목적
- MVP 구현에 필요한 의존성을 `필수/선택`으로 구분한다.
- 각 의존성별로 `코드 작업`과 `수동 설정 작업`을 분리한다.

## 2. 필수 의존성 (MVP)
1. Apple Frameworks
- `SwiftUI`: UI
- `SwiftData`: 로컬 저장
- `UserNotifications`: 리마인드 알림
- `FamilyControls`: 앱 선택/권한
- `ManagedSettings`: Shield 정책 적용
- `DeviceActivity`: 사용 시간 이벤트 모니터링
- `AppIntents`: 단축어 연동

2. 외부 라이브러리
- MVP 1차는 외부 라이브러리 `미사용` 권장
- 이유: Screen Time/Extension 중심 앱은 iOS 프레임워크 의존이 이미 높고, 초기 안정화가 더 중요

## 3. 선택 의존성 (MVP 후반 또는 다음 단계)
1. 로깅/분석
- Firebase Analytics
- Mixpanel

2. 크래시 모니터링
- Firebase Crashlytics
- Sentry

3. 원격 설정
- Firebase Remote Config

## 4. 의존성별 작업 분류
### 4.1 SwiftData
- 코드로 해결
  - 모델 정의
  - Repository 구현
  - 마이그레이션 정책(초기 버전)
- 수동 작업
  - 없음

### 4.2 UserNotifications
- 코드로 해결
  - 권한 요청
  - 종료 N분 전 리마인드 예약
- 수동 작업
  - iOS 설정에서 사용자가 알림을 꺼둘 수 있음 (QA 시 확인 필요)

### 4.3 FamilyControls / ManagedSettings / DeviceActivity
- 코드로 해결
  - 권한 요청 UX
  - 앱 선택/정책 저장
  - Shield 구성/액션 처리
- 수동 작업
  - Apple Developer 계정에서 관련 Capability/Entitlement 설정
  - 실제 디바이스 테스트(시뮬레이터 한계)

### 4.4 AppIntents
- 코드로 해결
  - 빠른 목표 시작 Intent
  - 즐겨찾기 목표 시작 Intent
- 수동 작업
  - Shortcuts 앱에서 노출/실행 확인

### 4.5 Firebase/Sentry (선택)
- 코드로 해결
  - SDK 추가
  - 이벤트/크래시 전송 코드
- 수동 작업
  - 콘솔 로그인
  - 앱 등록
  - `GoogleService-Info.plist` 또는 DSN 발급/등록
  - API 키/프로젝트 식별자 환경별 관리

## 5. API 키/로그인 필요 여부 요약
1. MVP 필수 범위만 구현 시
- 별도 외부 API 키 `불필요`
- Apple Developer 로그인/서명 설정은 `필수`

2. 분석/크래시 도구 추가 시
- 서비스 콘솔 로그인 `필수`
- SDK 설정 파일/API 키 관리 `필수`

## 6. 의존성 도입 순서
1. Apple 기본 프레임워크만으로 MVP 흐름 완성
2. TestFlight 내부 테스트 안정화
3. 분석/크래시 SDK를 필요할 때 최소 범위로 추가

## 7. 개발 환경 전제 조건 (추가)
- iOS Deployment Target: 17.0+
- Xcode: 16.x 권장
- 시뮬레이터는 UI/기본 로직 확인용
- 실기기 필수: FamilyControls/ManagedSettings/DeviceActivity/Shortcuts
- 최소 버전 미만이면 BLOCKED_MANUAL 처리
