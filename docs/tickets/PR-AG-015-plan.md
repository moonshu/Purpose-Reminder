# PR-AG-015 Plan — 수동 작업 창구 통합 문서화

## 1. 목표
- 사람이 개입해야 하는 작업을 한 곳에서 찾을 수 있도록 문서 진입점을 통합한다.

## 2. 선행 조건
- 없음

## 3. 변경 대상
- `docs/README.md`
- `docs/ios-manual-setup-checklist.md`
- `docs/agent-ticket-spec.md` (BLOCKED_MANUAL 포맷 참조)

## 4. 구현 단계
1. README에 단일 수동 작업 창구 섹션 추가
2. 체크리스트 링크/우선순위/담당자 규칙 명시
3. BLOCKED_MANUAL 전환/복귀 절차 연결
4. 신규 참여자 온보딩 동선 점검

## 5. 검증
- 문서 첫 방문자가 1분 내 수동 작업 위치를 찾을 수 있는지 확인
- BLOCKED 발생 시 기록 템플릿으로 바로 작성 가능한지 확인

## 6. 완료 기준 (DoD)
- 수동 작업 문서 링크가 단일 진입점으로 통합
- 수동 작업 누락 시점이 명확히 식별 가능
- BLOCKED_MANUAL 처리 절차가 README와 spec에 일관되게 명시

## 7. BLOCKED_MANUAL 조건
- 없음 (문서 작업만 수행)

## 8. 산출물
- 통합 안내 섹션
- BLOCKED 처리 흐름 링크
