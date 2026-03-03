# Purpose Reminder iOS Technical Architecture (MVP)

## 1. 목적
- 이 문서는 `docs/ios-mvp-spec.md`를 실제 구현 가능한 기술 구조로 변환한 문서다.
- 목표: 팀이 같은 폴더 구조, 같은 책임 분리, 같은 의존성 원칙으로 개발하게 만드는 것.

## 2. 아키텍처 원칙
1. `기능 단위(Feature-first)` 폴더 구조
2. `도메인 로직`과 `iOS 프레임워크 연동` 분리
3. Extension 코드와 Main App 코드의 경계 명확화
4. MVP는 로컬 우선(서버/클라우드 제외)

## 3. 권장 프로젝트 구조
```text
PurposeReminder/
  App/
    PurposeReminderApp.swift
    AppRouter.swift
  Core/
    Models/
      AppPolicy.swift
      GoalTemplate.swift
      GoalSession.swift
      ReminderEvent.swift
    Storage/
      SwiftDataStack.swift
      Repositories/
        AppPolicyRepository.swift
        GoalTemplateRepository.swift
        GoalSessionRepository.swift
    Services/
      ScreenTime/
        AuthorizationService.swift
        AppSelectionService.swift
        ShieldPolicyService.swift
      Session/
        SessionCoordinator.swift
        ReminderScheduler.swift
      Shortcuts/
        AppIntentBridge.swift
    Shared/
      Constants.swift
      Logger.swift
      TimeProvider.swift
  Features/
    Onboarding/
    PolicySettings/
    GoalTemplates/
    SessionStart/
    SessionActive/
    History/
  Extensions/
    ShieldConfigurationExtension/
    ShieldActionExtension/
    DeviceActivityMonitorExtension/
  Resources/
  Tests/
    Unit/
    Integration/
```

## 4. 모듈 책임
1. `Core/Models`
- 비즈니스 엔티티 정의 (UI/프레임워크 독립)

2. `Core/Storage`
- SwiftData 모델 매핑, CRUD, 쿼리 담당

3. `Core/Services/ScreenTime`
- FamilyControls 권한/앱선택/Shield 정책 적용

4. `Core/Services/Session`
- 세션 시작/종료/연장/타임아웃 상태 전이
- 리마인드 스케줄링과 이벤트 기록

5. `Features/*`
- 화면별 View + ViewModel
- 화면 단의 상태/입력 처리

6. `Extensions/*`
- Shield UI/액션/모니터링 확장 포인트 구현

## 5. 데이터 흐름
1. 사용자가 대상 앱 진입
2. Shield Action -> 목표 선택 트리거
3. `SessionCoordinator.startSession(...)`
4. 정책 기반 임시 허용 + 리마인드 예약
5. 종료 시 상태 업데이트 + 기록 저장

## 6. 상태 관리 원칙
- View는 `ViewModel`만 호출
- ViewModel은 Repository/Service 인터페이스만 의존
- 상태 전이 규칙은 `SessionCoordinator` 1곳에서만 관리

## 7. 테스트 전략 (MVP)
1. Unit Test
- 세션 상태 전이
- 빠른 목표 정렬 우선순위
- 리마인드 스케줄 계산

2. Integration Test
- SwiftData 저장/조회
- SessionCoordinator + Repository 결합 시나리오

3. Manual QA
- 실제 기기에서 Screen Time 권한/Shield 개입 확인

## 8. 확장 고려사항 (MVP 이후)
- 서버 동기화 추가 시 Repository 뒤에 RemoteDataSource 추가
- AI 코칭 추가 시 Goal/Session 이벤트 스트림 재사용
