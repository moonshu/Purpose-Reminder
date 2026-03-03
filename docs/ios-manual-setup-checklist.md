# Purpose Reminder iOS Manual Setup Checklist

## 1. 목적
- 코드로 해결되지 않는 수동 작업을 누락 없이 수행하기 위한 체크리스트.
- 담당자가 바뀌어도 동일하게 재현 가능하도록 작성.

## 2. Apple Developer / Xcode 설정
- [ ] Apple Developer 계정 로그인
- [ ] 앱 Bundle ID 생성
- [ ] App ID Capability 확인 (Screen Time 관련)
- [ ] Main App + Extension 타겟 Signing 설정
- [ ] Team/Provisioning Profile 연결

## 3. 권한/환경 확인
- [ ] 실기기에서 Screen Time 권한 요청/승인 확인
- [ ] 실기기에서 알림 권한 요청/승인 확인
- [ ] 대상 앱 선택 UI가 정상 노출되는지 확인
- [ ] Shield 개입이 실제 대상 앱에서 발생하는지 확인

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
