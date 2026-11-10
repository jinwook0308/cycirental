# CYCIRENTAL 모바일 앱

Flutter / Material 3 기반 Android 앱입니다. Android Studio에서 이 `mobile` 폴더를 열고 Medium Phone 에뮬레이터로 Run합니다.

## 실행 설정

기본 실행에서는 로컬 백엔드를 8080으로 켜고, Device Manager와 상단 기기 선택에서 **Medium Phone**을 선택합니다. API 주소는 `http://10.0.2.2:8080`을 그대로 사용하며 별도 설정 파일은 필요하지 않습니다.

Android Studio Terminal에서 Medium Phone을 자동 선택하려면:

```powershell
.\tool\run_medium_phone.cmd
```

회원가입은 이름·학번·비밀번호·비밀번호 확인·전화번호, 로그인은 학번·비밀번호를 입력합니다. 별도 아이디·이메일은 보내지 않습니다.

### 다른 서버가 필요할 때만

`config/local-api.json`을 로컬에 생성합니다. 파일은 Git에서 제외됩니다.

```json
{"API_BASE_URL":"http://your-server-host:8081"}
```

Run → Edit Configurations → Additional run args:

```text
--dart-define-from-file=config/local-api.json
```

주소 변경 후에는 실행을 종료하고 다시 Run합니다. APK를 따로 설치하지 않아도 됩니다.
설정이 없으면 Android 에뮬레이터용 `http://10.0.2.2:8080`을 사용합니다.

## 연결 범위

| 기능 | 현재 로컬 구현 |
| --- | --- |
| 물품 목록·수량 조회 | GET /api/items 연결, 조회 결과로 검색·상세 표시 |
| 가입·학번 로그인·로그아웃 | 실제 인증 API 연결 코드 구현 |
| 관리자 권한 | 로그인 응답 isAdmin=true일 때 메뉴 표시 |
| 비밀번호 초기화 | 관리자 확인·임시 비밀번호·변경 강제 API와 화면 구현 |
| 대여·승인·거절·취소·반납 | 같은 앱 메모리에서만 처리, 재실행 시 초기화 |
| 관리자 물품 등록·수정 | 메모리에서만 처리 |
| 공지 작성·수정·삭제·중요 지정 | 메모리에서만 처리 |
| 알림 설정 | 화면의 스위치 상태만 변경, 저장·푸시 미연결 |
| 관리자 웹 | 미구현 |

화면·API 코드 구현 완료가 원격 DB 적용이나 배포 완료를 뜻하지 않습니다. 서로 다른 기기의 대여·반납·공지 변경은 아직 공유되지 않습니다.

자세한 실행·검증은 [DEVELOPMENT.md](../DEVELOPMENT.md), API 계약은 [FRONTEND_API_HANDOFF.md](../FRONTEND_API_HANDOFF.md)를 확인합니다.
