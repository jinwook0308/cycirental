# CYCIRENTAL Frontend

학과에서 보유하고 있는 대여 물품을 모바일에서 조회하고,
대여 신청 및 자신의 대여 현황을 관리할 수 있도록 개발하는
**CYCIRENTAL 모바일 앱의 Frontend 저장소**입니다.

Frontend는 **Flutter / Dart**를 사용합니다.

---

## 저장소

- **Frontend:** 현재 저장소
- **Backend:** [CYCIRENTAL Backend](https://github.com/cycirental-team/cycirental-backend)

Frontend와 Backend는 각각 별도의 저장소에서 개발하며 REST API를 통해 연동합니다.

---

## Frontend 담당 범위

이 저장소에서는 모바일 애플리케이션의 화면 및 사용자 기능을 개발합니다.

주요 범위는 다음과 같습니다.

- 로그인 / 회원가입
- 홈 화면
- 공지사항
- 대여 물품 목록
- 물품 검색
- 물품 상세 정보
- 대여 신청
- 내 대여 현황
- 반납 예정 정보
- 사용자 설정
- Backend API 연동
- 전체 UI / UX

Backend API, Database 및 서버 관련 내용은
[Backend 저장소](https://github.com/cycirental-team/cycirental-backend)에서 관리합니다.

---

## 개발 환경

| 구분 | 사용 기술 |
| --- | --- |
| Framework | Flutter |
| Language | Dart |
| IDE | Android Studio / VS Code |
| Target | Android |

Flutter 프로젝트는 저장소의 `mobile` 폴더에 있습니다.

```text
cycirental
├─ mobile
│  ├─ android
│  ├─ lib
│  ├─ test
│  └─ pubspec.yaml
│
├─ README.md
├─ DEVELOPMENT.md
├─ SETUP_WINDOWS.md
├─ CONTRIBUTING.md
└─ TEAM.md
```

---

## 프로젝트 실행

### 1. 저장소 받기

Windows에서는 한글이나 OneDrive가 포함되지 않은
짧은 영문 경로 사용을 권장합니다.

```text
C:\dev\cycirental
```

```powershell
git clone https://github.com/jinwook0308/cycirental.git C:\dev\cycirental
cd C:\dev\cycirental
```

### 2. Flutter 패키지 설치

```powershell
cd mobile
flutter pub get
```

### 3. 앱 실행

Android Emulator 또는 Android 기기를 연결한 뒤 실행합니다.

```powershell
flutter devices
flutter run
```

Android Studio를 사용하는 경우 저장소 전체가 아니라
다음 폴더를 Flutter 프로젝트로 엽니다.

```text
cycirental\mobile
```

---

## 개발 환경 확인

```powershell
flutter doctor -v
flutter devices
```

자세한 설정 방법은 다음 문서를 참고합니다.

- [Windows 개발 환경 설정](SETUP_WINDOWS.md)
- [Frontend 개발 안내](DEVELOPMENT.md)

---

## 테스트 및 확인

작업 후 가능한 범위에서 다음 명령으로 오류를 확인합니다.

```powershell
cd mobile

dart analyze lib
flutter test
flutter build apk --debug
```

Merge 전에는 최소한 수정한 기능이 실제 앱에서 정상적으로 동작하는지 확인합니다.

---

## Backend 연동

Backend는 별도 저장소에서 개발합니다.

- [CYCIRENTAL Backend](https://github.com/cycirental-team/cycirental-backend)

로컬 Backend의 기본 개발 포트는 `8080`입니다.

Android Emulator에서 개발 PC에서 실행 중인 Backend에 접근할 경우:

```text
http://10.0.2.2:8080
```

을 사용합니다.

Android Emulator에서 `127.0.0.1` 또는 `localhost`는
개발 PC가 아닌 Emulator 자신을 가리킵니다.

실제 서버 및 Backend 실행 방법은 Backend 저장소의 README를 기준으로 합니다.

---

# GitHub 작업 흐름

Frontend는 다음 브랜치 흐름을 사용합니다.

```text
front/*
   ↓
front-dev
   ↓
main
```

### `main`

실행 및 제출 기준이 되는 안정화 브랜치입니다.

- 직접 기능 개발하지 않습니다.
- 검토 및 통합이 완료된 `front-dev`만 반영합니다.

### `front-dev`

Frontend 통합 브랜치입니다.

- Frontend 기능을 통합합니다.
- Frontend 기능 브랜치는 `front-dev`를 기준으로 생성합니다.
- 기능 간 연결 및 충돌 여부를 확인합니다.

### `front/*`

Frontend 기능 및 작업용 브랜치입니다.

예시:

```text
front/auth
front/home
front/items
front/rental
front/settings
front/docs-refactor
```

Commit, Pull Request, Code Review, Merge 등 자세한 공통 규칙은
[협업 규칙](CONTRIBUTING.md)을 기준으로 합니다.

---

## 관련 문서

- [Windows 개발 환경 설정](SETUP_WINDOWS.md)
- [Frontend 개발 안내](DEVELOPMENT.md)
- [공통 협업 규칙](CONTRIBUTING.md)
- [팀원 역할 및 담당](TEAM.md)
- [Backend 저장소](https://github.com/cycirental-team/cycirental-backend)

---

## 문서 관리

프로젝트 구조 또는 작업 방식이 변경된 경우 관련 문서도 함께 수정합니다.

- Frontend 사용 및 구조 → `README.md`
- Frontend 개발 세부 내용 → `DEVELOPMENT.md`
- Windows 개발 환경 → `SETUP_WINDOWS.md`
- Git / GitHub 협업 규칙 → `CONTRIBUTING.md`
- 팀원 역할 및 담당 → `TEAM.md`
- Backend / Database / 서버 / 배포 → Backend 저장소

Frontend와 관련 없는 Backend 운영 내용을 이 README에 중복 작성하지 않습니다.

---

## 확인 기록

- 2026-09-30 김명숙 - CYCIRENTAL Frontend 셋업 검사 완료
