# Purpose Reminder iOS MVP Spec

## 1. 문서 목적
- 이 문서는 `Purpose Reminder`의 iOS MVP 기준 스펙 문서다.
- 새 대화/새 에이전트 세션에서도 동일한 제품 컨텍스트를 유지하기 위한 기준 문서로 사용한다.
- 기준 우선순위는 "실행 가능성(iOS 정책) > 사용자 마찰 최소화 > 빠른 MVP 검증"이다.

## 2. 제품 정의
- 앱 성격: 관제탑(설정/기록/정책 관리)
- 개입 시점: 사용자가 대상 앱(예: Instagram)을 열려고 할 때
- 핵심 목표: 사용자가 목표를 설정하고, 목표 달성 전까지 리마인드를 받아 이탈을 줄이게 한다.

## 3. iOS 제약 및 구현 원칙
- iOS에서 Android식 자유 오버레이(타 앱 위 플로팅)는 불가.
- 임의 앱 실행을 일반 앱이 완전 자유 방식으로 실시간 가로채는 구조는 불가.
- 반드시 `Screen Time` 계열 API를 활용한다.
  - `FamilyControls`
  - `ManagedSettings`
  - `DeviceActivity`
- 타 앱 진입 개입은 `Shield` 기반으로 설계한다.

## 4. MVP 범위 (필수)
1. 대상 앱 선택/관리
2. 앱별 규칙 설정
- 기본 허용 시간(예: 10/20/30분)
- 리마인드 시점(예: 5분)
3. 목표 설정 방식
- 빠른 시작(최근/즐겨찾기/기본 목표) 우선
- 필요 시 새 목표 직접 입력
4. 세션 동작
- 세션 시작
- 사용 중 리마인드
- 시간 종료 후 완료/연장 선택
5. 기록 화면
- 오늘 세션 수
- 완료율
- 연장/중단 수
6. 단축어(Shortcuts) 연동
- 빠른 목표 시작
- 앱별 즐겨찾기 목표 원탭 시작

## 5. 사용자 플로우
1. 온보딩
- Screen Time 권한 허용
- 알림 권한 허용
2. 정책 설정
- 사용자 대상 앱 선택
- 앱별 기본 시간/리마인드/기본 목표 설정
3. 대상 앱 진입 시
- iOS Shield 개입
- 사용자 선택: `빠른 시작` 또는 `새 목표 입력`
4. 목표 확정 후
- 세션 시작
- 해당 앱 임시 허용
5. 세션 진행
- 중간 리마인드 알림 발송
6. 세션 종료
- 완료/연장/중단 선택
- 결과 기록 저장

## 6. 빠른 목표(마찰 최소화) 설계
### 6.1 목표 템플릿 소스
- 최근 사용 목표 (최근성 기준)
- 즐겨찾기 목표 (고정)
- 앱별 기본 목표 (기본값)

### 6.2 추천 정렬 우선순위
1. 즐겨찾기
2. 동일 앱에서 최근 사용
3. 전체 최근 사용
4. 새 목표 입력

### 6.3 원탭 시작
- 빠른 목표를 탭하면 즉시 세션 시작
- 입력 폼을 건너뛰어 사용 장벽 최소화

## 7. 데이터 모델 (MVP 최소)
### 7.1 AppPolicy
- `id`
- `appToken` (FamilyControls 선택 앱 식별 값)
- `isActive`
- `defaultDurationMinutes`
- `reminderOffsetMinutes`
- `defaultTemplateId` (nullable)

### 7.2 GoalTemplate
- `id`
- `targetAppToken` (nullable: 공용 템플릿 허용 시)
- `text`
- `isFavorite`
- `useCount`
- `lastUsedAt`
- `createdAt`

### 7.3 GoalSession
- `id`
- `targetAppToken`
- `templateId` (nullable)
- `goalTextSnapshot`
- `startedAt`
- `endedAt` (nullable)
- `status` (`active`, `completed`, `extended`, `abandoned`, `timed_out`)
- `plannedDurationMinutes`

### 7.4 ReminderEvent
- `id`
- `sessionId`
- `scheduledAt`
- `firedAt` (nullable)
- `action` (`ignored`, `opened`, `completed`, `extended`)

## 8. 상태 머신
- `idle -> pending_goal -> active -> reminded -> completed`
- `active -> extended`
- `active/reminded -> abandoned`
- `active/reminded -> timed_out`

## 9. iOS 앱 구성
1. Main App (설정/기록/템플릿/단축어 진입)
2. `ShieldConfigurationExtension`
3. `ShieldActionExtension`
4. `DeviceActivityMonitorExtension`

## 10. 화면 스펙 (MVP)
1. 온보딩/권한 화면
- Screen Time, 알림 권한 안내 및 허용
2. 대상 앱/규칙 설정 화면
- 앱 선택, 기본 시간, 리마인드 설정
3. 목표 템플릿 관리 화면
- 최근, 즐겨찾기, 기본 목표 지정
4. 세션 시작 화면
- 빠른 시작 목록 + 새 목표 입력
5. 기록 화면
- 오늘 기준 활동 요약 및 최근 세션

## 11. 단축어(App Intents) 스펙
1. `빠른 목표 시작`
- 파라미터: 대상 앱, 목표 템플릿, 시간
- 동작: 세션 생성 + 임시 허용 시작
2. `즐겨찾기 목표 시작`
- 파라미터 없이 기본 즐겨찾기/기본 정책으로 시작
- 홈 화면/액션 버튼에서 즉시 실행 가능

## 12. 기술 스택
- 언어/UI: Swift, SwiftUI
- 로컬 저장: SwiftData (초기)
- 알림: `UNUserNotificationCenter`
- 동기화/서버: MVP 1차는 제외 (로컬 우선)

## 13. 일정 (3주 MVP)
1. 1주차
- 권한 온보딩
- 대상 앱 선택/정책 저장
- Shield 기반 개입 골격
2. 2주차
- 빠른 목표(최근/즐겨찾기/기본 목표)
- 세션 시작/종료/연장 흐름
- 리마인드 알림
3. 3주차
- 단축어 연동
- 기록 화면
- 안정화 및 QA

## 14. KPI (MVP 검증 지표)
1. 개입 성공률 (대상 앱 진입 시 개입 발생 비율)
2. 목표 선택률 (빠른 시작 포함)
3. 세션 완료율
4. 연장 비율
5. 재방문율 (D1/D7)

## 15. 리스크 및 대응
1. Screen Time 관련 권한/배포 제약
- 대응: 초기에 권한/엔타이틀먼트 검증을 최우선으로 수행
2. iOS 정책상 오버레이 불가
- 대응: Shield + 알림 UX로 제품 정의를 고정
3. 입력 피로
- 대응: 빠른 목표/즐겨찾기/단축어를 MVP 필수로 유지

## 16. 비범위 (MVP 제외)
- Android 앱 동시 개발
- 고급 추천/AI 코칭
- 다중 디바이스 클라우드 동기화
- 소셜/랭킹 기능

## 17. 에이전트 작업 지침 (컨텍스트 유지용)
- 새 작업 세션 시작 시 이 문서를 먼저 읽고 스펙 기준으로 판단한다.
- iOS 정책과 충돌하는 요구가 나오면 이 문서의 "iOS 제약 및 구현 원칙"을 기준으로 대안을 제시한다.
- 목표 입력 UX는 "빠른 시작 우선" 원칙을 유지한다.
