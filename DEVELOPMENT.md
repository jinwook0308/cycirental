# CYCIRENTAL Frontend 개발 안내

CYCIRENTAL Frontend 개발에 필요한 기본 실행 방법과 개발 시 주의사항을 정리합니다.

처음 개발 환경을 구성하는 팀원은
[Windows 개발 환경 설정](SETUP_WINDOWS.md)을 먼저 확인합니다.

Backend 관련 실행 및 서버 설정은
[CYCIRENTAL Backend 저장소](https://github.com/cycirental-team/cycirental-backend)를 기준으로 합니다.

---

## 현재 Frontend 구성

Flutter 프로젝트는 저장소의 `mobile` 폴더에 있습니다.

```text
cycirental
└─ mobile
   ├─ android
   ├─ lib
   ├─ test
   └─ pubspec.yaml
```

Android Studio에서는 저장소 루트가 아니라 `mobile` 폴더를 프로젝트로 엽니다.

---

## 실행

```powershell
cd mobile
flutter pub get
flutter run
```

Android Emulator 또는 실제 Android 기기를 먼저 연결한 뒤 실행합니다.

연결된 기기는 다음 명령으로 확인합니다.

```powershell
flutter devices
```

---

## 개발 환경 확인

```powershell
flutter doctor -v
```

Flutter 및 Android toolchain 관련 오류가 있는 경우
[Windows 개발 환경 설정](SETUP_WINDOWS.md)의 오류 해결 내용을 확인합니다.

---

## 테스트

작업 후 가능한 범위에서 다음 명령을 실행합니다.

```powershell
cd mobile
dart analyze lib
flutter test
flutter build apk --debug
```

Merge 전에는 최소한 수정한 화면 또는 기능이 실제 앱에서 정상적으로 동작하는지 확인합니다.

---

## 앱 로그인 및 관리자 임시 기능

현재 로그인 API가 없어 계정·권한 확인은 로컬 데모 인증으로 동작합니다.

| 계정 | 아이디 | 비밀번호 | 권한 |
| --- | --- | --- | --- |
| 학생 데모 | student | student1234 | 학생 |
| 관리자 데모 | admin | admin1234 | 관리자 |

- 로그인 입력값이 데모 계정과 일치할 때만 해당 권한으로 진입합니다.
- 기존 **로그인 · 데모 체험** 버튼은 항상 학생으로 진입합니다.
- 관리자에게만 **설정 → 관리자**가 표시되며, 학생은 관리자 화면에 진입할 수 없습니다.
- 로그아웃하면 계정과 권한이 초기화됩니다.
- 실제 운영 전에는 데모 인증을 서버 로그인 응답으로 교체하고 관리자 API에서 권한을 검증해야 합니다.

관리자 기능은 현황, 물품 등록·수정, 학생 신청 승인·거절, 전체 학생 반납 확인입니다.
물품 조회는 기존 `/api/items` 연결을 유지하며 관리자 변경·대여·반납은 메모리에서만 처리합니다.
학생 신청은 관리자 승인 목록에 표시됩니다. 관리자 진입 시 샘플 신청을 자동 생성하지 않습니다.
조회 실패 시 관리자 물품 등록은 가능하지만, 학생 물품 목록은 기존 API 재시도 화면을 표시합니다.

수량 수정 시 기존 대여 중·사용 불가 수량을 보존해야 합니다. 로컬 관리자 물품 수정은 API 새로고침 후에도 유지되며 앱 종료 시 초기화됩니다.
다른 학생의 신청 승인 내역은 현재 로그인한 계정의 **내 대여**에 섞이지 않습니다.
웹 관리자 화면과 서버 저장 기능은 이번 작업 범위에 포함하지 않습니다.

---

## Backend 연동

Backend는 별도 저장소에서 관리합니다.

- [CYCIRENTAL Backend](https://github.com/cycirental-team/cycirental-backend)

로컬 Backend 기본 주소:

```text
http://127.0.0.1:8080
```

Android Emulator에서 개발 PC의 Backend에 접근할 경우:

```text
http://10.0.2.2:8080
```

을 사용합니다.

현재 앱의 기본 주소는 에뮬레이터용 `http://10.0.2.2:8080`입니다. 팀 서버는 `config/local-api.json`의 `API_BASE_URL`로 지정하며 이 파일은 Git에서 제외됩니다.
Backend 주소를 변경할 때는 `API_BASE_URL`을 빌드 시 전달합니다.

```powershell
flutter run --dart-define=API_BASE_URL=http://서버주소:포트
```

실제 Android 기기에서는 `10.0.2.2`를 사용할 수 없습니다. 개발 PC와 같은 네트워크에
연결한 뒤 개발 PC의 LAN 주소를 사용하거나, 배포된 Backend 주소를 지정합니다.

물품 조회 실패 시 앱에는 재시도 화면이 표시됩니다. Backend의 `/api/health`와
`/api/items`가 정상 응답하는지 먼저 확인합니다.

실제 서버 주소, API 목록, MariaDB 연결 및 자동 배포 방식은 Backend 저장소 문서를 기준으로 합니다.

---

## Git 작업

Frontend 작업은 다음 흐름을 사용합니다.

```text
front/*
   ↓
front-dev
   ↓
main
```

자세한 브랜치, Commit, Pull Request 및 Code Review 규칙은
[CONTRIBUTING.md](CONTRIBUTING.md)를 확인합니다.

---

## 문서 수정

Frontend 구조 또는 실행 방식이 변경된 경우 관련 문서도 함께 수정합니다.

- Frontend 개요 및 실행 → `README.md`
- Frontend 개발 세부 내용 → `DEVELOPMENT.md`
- Windows 개발 환경 → `SETUP_WINDOWS.md`
- 공통 Git / GitHub 규칙 → `CONTRIBUTING.md`
- 팀원 역할 → `TEAM.md`

Backend, Database 및 서버 운영 내용을 Frontend 문서에 중복해서 작성하지 않습니다.

## 최대 대여 기간

반납 예정일은 신청일 다음 날부터 14일 뒤까지 선택할 수 있습니다. 날짜 선택 UI, 대여 신청, 관리자 승인에서 같은 제한을 검증합니다. 관리자 승인은 원래 신청일 기준의 14일을 유지하며 기간 초과·이미 지난 반납일은 승인하지 않습니다. 실제 대여 API 연동 시 서버에도 같은 규칙을 적용해야 합니다.

## 대여 승인 흐름

학생 신청 → 승인 대기 → 관리자 승인 → 대여 중 → 반납 완료 순서입니다. 학생의 내 대여 화면은 신청 내역·대여 중·대여 내역으로 구분하며, 거절된 신청은 신청 내역에 표시합니다. 같은 학생의 같은 물품에 대한 중복 대기 신청은 차단합니다. 승인 대기는 재고를 차감하지 않으며 승인 시 재고와 최대 14일 제한을 재검증합니다. 학생과 관리자 로그인은 로그아웃 후 전환하여 같은 앱에서 테스트할 수 있습니다. 다른 기기 간 공유와 서버 저장은 아직 연결되지 않았습니다.

## 신청 및 반납 상태 관리

- 승인 대기 신청은 학생이 확인 다이얼로그를 거쳐 취소할 수 있습니다. 다른 학생의 신청이나 이미 승인·거절·만료된 신청은 취소할 수 없습니다.
- 관리자가 거절할 때 1~300자의 사유를 입력해야 하며 학생의 신청 내역과 알림에 표시합니다.
- 반납 예정일 당일이 되어 더 이상 승인할 수 없는 신청은 만료로 변경하여 관리자 승인 대기에서 제외합니다. 앱이 열린 동안 매분 확인하며 로그인·앱 복귀·승인·거절·취소 시에도 확인합니다.
- 학생의 반납 요청은 관리자 확인 대기 상태로 남으며 재고를 복구하지 않습니다. 관리자가 실물 반납 확인 다이얼로그를 승인해야 반납 완료·대여 내역 이동·재고 복구가 일어납니다.
- 중복 반납 요청 및 중복 확인은 차단합니다. 반납 확인 대기 중에도 대여 중 수량에 포함합니다.

상태 관리는 현재 같은 앱의 메모리에서만 유지됩니다. 실제 서비스 연결 시 서버가 동일한 권한과 상태 전환을 검증해야 합니다.

## 로컬 서버 설정 (Git 제외)

`mobile/config/local-api.json`을 로컬에서 생성합니다. 파일 형식:

```json
{"API_BASE_URL":"http://서버주소:포트"}
```

`mobile` 폴더에서 실행 또는 빌드합니다.

```powershell
flutter run --dart-define-from-file=config/local-api.json
flutter build apk --debug --dart-define-from-file=config/local-api.json
```

설정 파일은 `.gitignore`에 등록되어 있으며 실제 서버 주소를 코드나 문서에 기록하지 않습니다.
새 PC에서는 설정 파일을 직접 생성해야 합니다. 생성된 APK에는 연결을 위해 서버 주소가 포함됩니다.
## 공지 관리·회원가입·이용 안내 화면

- 관리자 로그인 → 설정 → 관리자 → 공지 관리: 공지 작성·수정·삭제 및 중요 공지 지정
- 홈: 중요 공지 우선, 같은 중요도에서는 최근 수정 공지 1개 표시. 공지가 없으면 빈 상태 표시
- 홈 더보기 또는 설정 → 공지사항: 학생 공지 목록·상세 조회
- 로그인 → 회원가입: 학생 가입 입력 폼과 검증. API 미연결이므로 실제 계정은 생성하지 않음
- 설정 → 이용 안내: 대여 신청·승인·수령·반납·문의 안내

공지 변경은 같은 앱의 메모리에만 반영됩니다. 물품 API 조회 실패 시에도 홈의 공지는 표시하며, 물품 오류는 추천 물품 영역에 별도로 표시합니다.
백엔드 전달 사항은 [FRONTEND_API_HANDOFF.md](FRONTEND_API_HANDOFF.md)를 참고합니다. 기존 물품 조회 API 및 로컬 서버 설정은 유지합니다.