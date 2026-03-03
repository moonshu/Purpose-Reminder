# PR-AG-012 Plan — App Intents 2종 구현

## 1. 목표
- `빠른 목표 시작`, `즐겨찾기 목표 시작` Intent 2종을 구현하고 세션 시작 로직과 연결한다.

## 2. 선행 조건
- PR-AG-009 완료 (세션 시작 UI/로직)
- `Core/Services/Shortcuts` 기본 구조 존재

## 3. 변경 대상
- `PurposeReminder/Core/Services/Shortcuts/AppIntentBridge.swift`
- 필요 시 Intent 전용 파일 분리 (`QuickStartIntent.swift`, `FavoriteStartIntent.swift`)
- `docs/ios-manual-setup-checklist.md` (실기기 검증 항목 연결)

## 4. 구현 단계
1. Intent 파라미터/출력 정의 (`앱`, `목표`, `시간`)
2. Intent 실행 시 `SessionCoordinator` 호출 경로 연결
3. 에러/정책 누락 시 사용자 메시지 규칙 정의
4. 즐겨찾기 기본 정책 fallback 로직 추가

## 5. 검증
- 코드: Intent 핸들러 단위 테스트 1개 이상
- 수동: Shortcuts 앱에서 2개 Intent 노출/실행 확인

## 6. 완료 기준 (DoD)
- 타입/빌드 에러 0건
- Intent 2종 모두 호출 가능
- 최소 1개 자동 테스트 또는 테스트 불가 사유 기록
- 수동 검증 결과를 체크리스트 항목 번호로 기록

## 7. BLOCKED_MANUAL 조건
- Shortcuts 앱 실기기 검증 불가
- Signing/Entitlement 문제로 Intent 미노출

## 8. 산출물
- Intent 구현 코드
- 검증 로그/체크 결과
- 문서 동기화 반영
