# PR-AG-018 계획 — GoalTemplates 화면 및 정책 기본 템플릿 연결

## 0. 목적
- 빠른 시작의 데이터 소스인 GoalTemplate을 사용자에게 편집 가능하게 만들고, 정책 기본 템플릿을 UI에서 연결한다.

## 1. 현재 코드베이스 진단
- 저장소/API는 존재: `GoalTemplateRepository`, `defaultTemplateId(AppPolicy)`
- UI 미구현: `Features/GoalTemplates/GoalTemplatesView.swift` 플레이스홀더
- PolicySettings에서 defaultTemplate 지정 UI 없음

## 2. 범위
### In Scope
1. 템플릿 CRUD + 즐겨찾기 토글
2. 앱별/공용 템플릿 필터
3. PolicySettings에 기본 템플릿 선택 연결
4. 템플릿/정책 동기화 테스트

### Out of Scope
- AI 추천 텍스트 생성

## 3. 변경 대상 파일
- `PurposeReminder/Features/GoalTemplates/GoalTemplatesView.swift`
- `PurposeReminder/Features/PolicySettings/PolicySettingsView.swift`
- `PurposeReminderTests/GoalTemplatesViewModelTests.swift` (신규)

## 4. 구현 전략
1. ViewModel에서 템플릿 목록 로드/정렬(즐겨찾기, 최근 사용)
2. 생성/수정 시 text trim + 중복 정책 처리
3. defaultTemplate 지정 시 해당 정책의 `defaultTemplateId` 업데이트
4. SessionStart 추천 로직과 호환성 확인

## 5. 검증 명령
- `xcodebuild -project PurposeReminder.xcodeproj -scheme PurposeReminder -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' test -only-testing:PurposeReminderTests/GoalTemplatesViewModelTests`

## 6. 완료 기준 (DoD)
- 템플릿 CRUD 및 즐겨찾기 토글 동작
- PolicySettings에서 기본 템플릿 선택/저장이 가능

## 7. BLOCKED_MANUAL 조건
- 없음

## 8. 산출물
- GoalTemplates 화면 코드
- 템플릿/정책 연동 테스트
