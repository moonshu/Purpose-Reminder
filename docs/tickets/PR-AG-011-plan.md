# PR-AG-011 계획 — 기록 화면(History) 구현

## 0. 목적
- `HistoryView`를 실제 동작 화면으로 구현해 오늘 요약 지표와 최근 세션 목록을 제공한다.
- `Session/Storage`에 이미 있는 데이터를 UI로 안전하게 연결한다.

## 1. 현재 코드베이스 진단

### 이미 구현됨
- 세션 도메인 모델/저장소
  - `GoalSession`, `SessionStatus`
  - `GoalSessionRepository.fetch(from:to:)`
- 세션 엔진/리마인드 엔진
  - `SessionCoordinator`, `ReminderScheduler`
- 앱 라우터 기본 탭 구조
  - 파일: `PurposeReminder/App/AppRouter.swift`
  - 현재 탭: `SessionStartView`, `PolicySettingsView`

### 미구현/플레이스홀더
- `PurposeReminder/Features/History/HistoryView.swift` (플레이스홀더)
- 요약 집계 로직(완료율/중단/타임아웃) 부재
- History 관련 테스트 부재

## 2. 범위

### In Scope
1. `HistoryViewModel` + `HistoryView` 구현
2. 오늘 요약 지표 집계 규칙 정의
3. 최근 세션 목록(최신순) 렌더링
4. `AppRouter` 탭에 기록 화면 연결
5. ViewModel 단위 테스트 추가

### Out of Scope
- 기간 필터(주/월/커스텀) UI
- 차트/그래프 시각화

## 3. 변경 대상 파일
- `PurposeReminder/Features/History/HistoryView.swift`
- `PurposeReminder/App/AppRouter.swift`
- `PurposeReminderTests/HistoryViewModelTests.swift` (신규)

## 4. 구현 전략

### 4-1. 집계 규칙 고정
- `totalToday`: 오늘 시작한 세션 수
- `completedToday`: `status == .completed || .extended`
- `abandonedToday`: `status == .abandoned`
- `timedOutToday`: `status == .timedOut`
- `completionRate = completedToday / totalToday` (0 division 방지)

### 4-2. 조회 범위
- 오늘 요약: `startOfDay ~ nextDayStart`
- 최근 목록: 최근 7일(`now - 7d ~ now`) + `startedAt` 내림차순

### 4-3. UI 구성
- 섹션 1: 오늘 요약(총 세션, 완료율, 연장/중단/타임아웃)
- 섹션 2: 최근 세션 리스트
  - 항목: 목표 텍스트, 시작 시각, 상태 라벨, 계획 시간
- 로딩/오류 상태 분리

### 4-4. 라우팅 연결
- `AppRouter.MainTabView`에 `HistoryView` 탭 추가
- 권장 순서: `세션`, `기록`, `정책`

### 4-5. 테스트 전략
- 빈 데이터 시 요약 0 처리
- 상태 조합에 따른 완료율 계산
- 오늘/어제 경계 필터 정확성
- 최근 목록 정렬 보장

## 5. 검증 명령
- 빌드: `xcodebuild -project PurposeReminder.xcodeproj -scheme PurposeReminder -destination 'platform=iOS Simulator,name=iPhone 16' build`
- 테스트: `xcodebuild -project PurposeReminder.xcodeproj -scheme PurposeReminder -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:PurposeReminderTests/HistoryViewModelTests`

## 6. 완료 기준 (DoD)
- `HistoryView` 플레이스홀더 제거, 실제 데이터 렌더링
- `AppRouter`에서 기록 탭 접근 가능
- 테스트 최소 3개 이상 통과
- 시뮬레이터 더미 데이터로 요약/리스트 표시 확인

## 7. BLOCKED_MANUAL 조건
- 없음 (자동/시뮬레이터 검증 가능)

## 8. 산출물
- 기록 화면 구현 코드
- HistoryViewModel 테스트
- 라우팅 탭 연결 변경
