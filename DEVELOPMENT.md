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

현재 앱은 별도 설정이 없으면 위 주소의 `/api/items`를 호출합니다.
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
