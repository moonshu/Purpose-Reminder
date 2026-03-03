# Purpose Reminder iOS Manual Setup Checklist

## 00. 수동 개입 전체 요약
- 이 문서는 에이전트가 대신 처리할 수 없는 항목의 단일 진입점이다.

### 최초 셋업 순서
1. Apple Developer 로그인/서명 연결 (§2)
2. Screen Time + App Group + Extension 포인트 확인 (§2)
3. 실기기 권한 승인(Screen Time/알림) (§3)
4. 정책 저장 + Shield 개입 확인 (§3, §8)
5. Shortcuts Intent 노출/실행 확인 (§4)

### BM 코드 매핑
| BM 코드 | 발생 조건 | 해소 작업 | 재개 조건 |
|---|---|---|---|
| BM-010-01 | 리마인드 수동 수신 검증 불가 | 실기기에서 알림 허용 후 세션 실행 | 리마인드 알림 1회 수신 확인 |
| BM-012-01 | Shortcuts에서 Intent 미노출 | 실기기 빌드 후 Shortcuts 앱 재색인/재실행 | Quick/Favorite Intent 노출 확인 |
| BM-012-02 | Siri/Signing 설정 누락 | Xcode Signing & Capabilities에서 Siri 추가 | 빌드 성공 + Intent 노출 |
| BM-013-01 | 실기기 접근 불가 | 실기기 확보 후 E2E-01~04,06 실행 | 필수 E2E 결과 기록 완료 |
| BM-013-02 | FamilyControls/Entitlement 미설정 | App ID/Capability/Entitlement 재설정 | 정책 저장 + Shield 개입 확인 |

### BLOCKED -> READY 전환 절차
1. BM 코드 대응 수동 작업 수행
2. §10 증적 규칙으로 결과 기록
3. 백로그 티켓 상태를 `BLOCKED_MANUAL`에서 `READY`로 변경
4. 재개 프롬프트에 BM 코드와 해소 내용을 포함

## 1. 목적
- 코드로 해결되지 않는 수동 작업을 누락 없이 수행하기 위한 체크리스트.
- 담당자가 바뀌어도 동일하게 재현 가능하도록 작성.

## 2. Apple Developer / Xcode 설정
- [ ] Apple Developer 계정 로그인
- [ ] 앱 Bundle ID 생성
- [ ] App ID Capability 확인 (Screen Time 관련)
- [ ] Main App + Extension 타겟 Signing 설정
- [ ] Main App + ShieldActionExtension에 동일 App Group(`group.com.purposereminder.shared`) 설정
- [ ] ShieldConfiguration/ShieldAction/DeviceActivity Extension 포인트 연결 확인
- [ ] Team/Provisioning Profile 연결

## 3. 권한/환경 확인
- [ ] 실기기에서 Screen Time 권한 요청/승인 확인
- [ ] 실기기에서 알림 권한 요청/승인 확인
- [ ] 대상 앱 선택 UI가 정상 노출되는지 확인
- [ ] Shield 개입이 실제 대상 앱에서 발생하는지 확인
- [ ] Shield primary 버튼 탭 후 App Group `shield.lastEvent` 값 갱신 확인
- [ ] Entitlement/App Group 누락 시 primary 버튼이 `.close`로 폴백되는지 확인

## 4. 단축어(Shortcuts) 검증
- [ ] `빠른 목표 시작` Intent 노출 확인
- [ ] `즐겨찾기 목표 시작` Intent 노출 확인
- [ ] 홈 화면/단축어 앱에서 실행 성공 확인

## 5. 배포 준비
- [ ] 버전/빌드 넘버 업데이트
- [ ] Archive 빌드 성공
- [ ] TestFlight 업로드
- [ ] 내부 테스터 초대

## 6. 선택: 외부 서비스 연동 시 추가 작업
### 6.1 Firebase (Analytics/Crashlytics)
- [ ] Firebase 콘솔 로그인
- [ ] iOS 앱 등록
- [ ] `GoogleService-Info.plist` 다운로드/연결
- [ ] 이벤트/크래시 수집 확인

### 6.2 Sentry
- [ ] Sentry 콘솔 로그인
- [ ] 프로젝트 생성
- [ ] DSN 발급/설정
- [ ] 테스트 에러 전송 확인

## 7. 운영 기준
- 위 체크리스트 중 하나라도 미완료면 "배포 준비 완료"로 판단하지 않는다.

## 8. Stage 1 실기기 개입 시나리오
- [ ] 대상 앱 1개 이상 정책 저장
- [ ] 대상 앱 진입 시 Shield UI(제목/버튼) 노출 확인
- [ ] Shield `목표 선택` 탭 시 액션 라우팅 이벤트 저장 확인
- [ ] Shield `지금은 닫기` 탭 시 Shield 종료 및 액션 이벤트 저장 확인

## 9. Edge Case 시나리오 (추가)
- [ ] Screen Time 권한 거부 처리 확인
- [ ] 알림 권한 거부 처리 확인
- [ ] Entitlement/App Group 누락 폴백 확인
- [ ] 정책/토큰 누락 안전 실패 확인

## 10. 증적 기록 규칙 (추가)
- [ ] 실행 시각/기기/OS 버전 기록
- [ ] 실패 시 스크린샷 또는 로그 첨부
- [ ] BLOCKED_MANUAL 전환 시 BM 코드 기록
