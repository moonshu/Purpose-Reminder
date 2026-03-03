# PR-AG-015 계획 — 수동 작업 창구 통합 문서화

## 0. 목적
- 사람이 직접 처리해야 하는 작업을 한 곳에서 찾고, BLOCKED 해소 후 재개까지 한 흐름으로 연결한다.
- 신규 참여자가 문서 탐색에 시간을 쓰지 않도록 "단일 진입점"을 만든다.

## 1. 현재 문서 상태 진단

### 이미 존재
- `docs/ios-manual-setup-checklist.md`: 수동 체크 항목 상세
- `docs/agent-ticket-spec.md`: BLOCKED_MANUAL 표준 포맷
- `docs/README.md`: 사람 개입 필요 창구(요약 링크)

### 현재 갭
- BM 코드별 해소 방법/담당/재개 조건이 한 문서에 모여있지 않음
- BLOCKED → READY 복귀 절차가 README에서 바로 보이지 않음
- 신규 참여자용 "첫 5분 가이드" 부재

## 2. 범위

### In Scope
1. 체크리스트 문서에 "수동 개입 요약" 섹션 신설
2. BM 코드 매핑표(조건/해소법/재개 조건) 통합
3. README에서 단일 진입 링크와 빠른 동선 제공
4. BLOCKED → READY 재개 절차 명시

### Out of Scope
- BM 코드 체계 자체 재설계
- 자동 티켓 상태 변경 도구 개발

## 3. 변경 대상 파일
- `docs/ios-manual-setup-checklist.md`
- `docs/README.md`
- `docs/agent-mvp-ticket-backlog.md` (필요 시 BM 코드 인덱스 링크)

## 4. 문서 설계

### 4-1. 단일 진입점 설계
- 체크리스트 최상단에 "00. 수동 개입 전체 요약" 추가
- 포함 내용:
  - 최초 셋업 순서
  - BM 코드 매핑표
  - BLOCKED → READY 전환 절차

### 4-2. BM 코드 매핑표 원칙
- 코드당 1행 유지
- 필수 열: BM 코드 / 발생 조건 / 담당자 / 해소 작업 / 재개 조건
- 티켓별 상세 계획과 코드 일치 보장

### 4-3. README 동선 최적화
- "사람 개입 필요 창구"에서 체크리스트 §00으로 바로 유도
- BLOCKED 포맷 문서(`agent-ticket-spec.md`)로 즉시 이동 가능하게 링크

### 4-4. 재개 절차 표준
1. 수동 작업 수행
2. 증적 기록(일시/기기/결과)
3. 백로그 상태 `BLOCKED_MANUAL -> READY` 변경
4. 재개 프롬프트 템플릿 사용

## 5. 검증 명령
- `rg -n "수동 개입|BLOCKED|BM-" docs/ios-manual-setup-checklist.md docs/README.md`
- `rg -n "BLOCKED_MANUAL" docs/agent-ticket-spec.md docs/agent-mvp-ticket-backlog.md`

## 6. 완료 기준 (DoD)
- 체크리스트에 단일 진입 요약 섹션이 추가됨
- BM 코드 매핑표로 해소 경로를 즉시 찾을 수 있음
- README에서 수동 작업 진입 경로가 1분 내 파악 가능

## 7. BLOCKED_MANUAL 조건
- 없음 (문서 작업)

## 8. 산출물
- 통합 수동 작업 진입 섹션
- BM 코드 매핑표 + 재개 절차
