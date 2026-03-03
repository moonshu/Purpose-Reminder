# PR-AG-014 계획 — 문서 동기화 자동화 규칙 정리

## 0. 목적
- 코드 변경 후 문서 누락(드리프트)을 줄이기 위한 동기화 규칙을 표준화한다.
- 티켓 완료 보고 시 문서 갱신 여부를 기계적으로 확인할 수 있게 만든다.

## 1. 현재 문서 상태 진단

### 이미 존재
- `docs/README.md`에 동기화 규칙 3줄 요약
- `docs/agent-ticket-spec.md`에 DoD/BLOCKED 포맷
- `docs/agent-mvp-ticket-backlog.md`에 티켓별 개요

### 현재 갭
- 변경 영역별 필수 갱신 문서 매핑이 없음
- "문서 변경 없음" 판단 기준이 모호함
- 티켓 완료 보고 템플릿이 없어 결과 형식이 매번 달라짐

## 2. 범위

### In Scope
1. 문서 Source of Truth 우선순위 명시
2. 변경 영역-문서 매핑 테이블 정의
3. 완료 보고 템플릿 표준화
4. 체크 명령(`rg`) 기반 최소 검증 규칙 제공

### Out of Scope
- CI 파이프라인 자동 검증 스크립트 구현
- 외부 문서 시스템(Notion/Jira) 동기화

## 3. 변경 대상 파일
- `docs/README.md`
- `docs/agent-ticket-spec.md`
- `docs/agent-mvp-ticket-backlog.md` (완료 보고 예시 링크 필요 시)

## 4. 규칙 설계

### 4-1. Source of Truth 우선순위
1. 제품 범위/정책: `ios-mvp-spec.md`
2. 구현 구조: `ios-technical-architecture.md`
3. 실행 단위: `agent-mvp-ticket-backlog.md`
4. 수동 작업: `ios-manual-setup-checklist.md`

### 4-2. 변경 영역별 문서 매핑(예시)
- `Core/Models`, `Core/Storage`: 아키텍처 문서 + 관련 티켓 계획
- `Core/Services/ScreenTime`, `Extensions`: 의존성/수동체크 문서
- `Features/*`: MVP 스펙 화면 정의 + 백로그
- `docs/tickets/*`: 백로그 링크 동기화

### 4-3. 완료 보고 템플릿
- 티켓 ID
- 코드 변경 파일
- 실행한 검증 명령/결과
- 수동 검증 항목 번호
- 문서 갱신 목록 또는 "변경 없음 + 근거"

### 4-4. 변경 없음 규칙
- 코드/동작/운영절차가 바뀌지 않았음을 한 줄 근거로 명시
- "시간 부족"은 근거로 인정하지 않음

## 5. 검증 명령
- `rg -n "문서 동기화 규칙|완료 보고" docs/README.md docs/agent-ticket-spec.md`
- `rg -n "PR-AG-01[0-5]-plan" docs/agent-mvp-ticket-backlog.md`

## 6. 완료 기준 (DoD)
- README에 동기화 매핑과 절차가 포함됨
- agent-ticket-spec에 완료 보고 템플릿이 포함됨
- 백로그에서 계획 문서 링크 누락이 없음

## 7. BLOCKED_MANUAL 조건
- 없음 (문서 작업)

## 8. 산출물
- 문서 동기화 규칙 확장본
- 티켓 완료 보고 템플릿
