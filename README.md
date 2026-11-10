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

로컬 백엔드를 8080으로 실행한 뒤 Medium Phone으로 앱을 켭니다. 아래 스크립트는 해당 에뮬레이터를 자동 선택합니다.

```powershell
flutter devices
.\tool\run_medium_phone.cmd
```

Android Studio를 사용하는 경우 저장소 전체가 아니라
다음 폴더를 Flutter 프로젝트로 엽니다.

```text
cycirental\mobile
```

Android Studio의 Device Manager에서 Medium Phone을 켜고 상단 기기 선택을 Medium Phone으로 지정해 Run해도 됩니다. 기본 API 주소는 `http://10.0.2.2:8080`이며, 다른 주소가 필요할 때만 로컬 실행 설정을 사용합니다. 자세한 실행 방법은 [개발 안내](DEVELOPMENT.md#android-studio-medium-phone-실행)를 확인합니다.

---

## 개발 환경 확인

```powershell
flutter doctor -v
flutter devices
```

자세한 설정 방법은 다음 문서를 참고합니다.

- [Windows 개발 환경 설정](SETUP_WINDOWS.md)
- [Frontend 개발 안내](DEVELOPMENT.md)
- [Git 업로드 전 준비](RELEASE_PREPARATION.md)

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

## 학생 화면

학생은 **홈 / 물품 / 내 대여 / 설정** 4개 하단 메뉴를 사용합니다. 알림은 상단 종 버튼에서 엽니다.

- 홈: 내 승인 대기·대여 중·오늘/내일 반납 임박 건수와 가까운 반납일을 먼저 표시합니다. 다른 계정의 기록과 이미 반납 요청한 물품은 다음 반납일에서 제외합니다.
- 상태 카드: 승인 대기는 신청 내역, 대여 중·반납 임박은 대여 중 내역으로 바로 이동합니다.
- 물품: 이름·카테고리·보관 장소 검색, 대여 가능 필터, 검색어 지우기, 당겨 새로고침을 지원합니다. 화면을 오가도 검색어가 유지됩니다.
- 상세: 설명·수량·보관 장소·반납 예정일을 정리하고 신청 버튼을 하단에 고정했습니다. 같은 물품의 승인 대기 신청이 있으면 중복 신청을 비활성화합니다.
- 내 대여: 신청·대여 중·완료 내역을 구분하고 상태에 따라 취소·반납 요청 버튼을 표시합니다. 반납 요청 후에는 관리자 확인 대기로 표시합니다.
- 알림: 현재 앱 기록으로 만든 대여 상태·반납 일정 안내이며, 읽음 상태 저장과 실제 푸시 발송은 아직 연결하지 않았습니다.
- 로그인·가입·프로필·설정은 관리자와 같은 보라색 디자인으로 통일하고 기존 입력 규칙과 인증 흐름을 유지합니다.

화면 개편은 대여·반납·공지의 원격 DB 연동 완료를 뜻하지 않습니다. 현재 연결 범위는 아래 Backend 연동 항목을 따릅니다.

## 관리자 전용 화면

서버의 `isAdmin=true` 응답으로 로그인한 관리자는 학생 홈을 거치지 않고 관리자 홈으로 진입합니다.
임시 비밀번호 사용 중에는 권한과 관계없이 비밀번호 변경을 먼저 완료해야 합니다.

- 관리자 홈: 운영 현황·최근 대기 신청 최대 5건·빠른 관리·대여 현황 요약
- 비밀번호 초기화 현황: 서버의 관리자 대기 목록을 조회해 처리할 요청 영역에 대여 신청·반납 요청과 같은 크기로 건수를 표시하고, 항목을 누르면 해당 요청 목록을 엽니다. 처리 후 돌아오거나 홈을 새로고침하면 갱신합니다. 조회 중·실패는 0건과 구분하며, API가 최대 100건을 반환하므로 100건부터는 100+건으로 표시합니다.
- 신청·반납·완료 내역에는 이름·학번을 표시하며 내부 사용자 ID는 노출하지 않습니다. 학번 없는 기존 메모리 기록은 학번 미등록으로 표시합니다.
- 홈 바로 처리: 학생·물품 확인 후 대여 승인 확정, 거절 사유 입력, 반납 확인 후 완료
- 전체 보기: 대여 신청·반납 요청·비밀번호 초기화 요청 중 목적지를 선택합니다. 현황 카드는 해당 상태의 목록을 엽니다.
- 하단 메뉴: 현황 / 물품 관리 / 대여 승인 / 반납 관리 / 공지 관리
- 계정 지원: 빠른 관리의 **계정 지원**에서 비밀번호 초기화 요청 확인·승인·거절을 진행합니다. 발급 비밀번호는 복사 버튼으로 복사할 수 있습니다.
- 관리자 정보 및 로그아웃: 빠른 관리의 계정 지원 메뉴 또는 상단 로그아웃
- 물품 검색: 이름·카테고리·보관 장소로 검색하고 대여 가능 여부로 필터링합니다.
- 대여·반납 목록: 상태별 필터와 건수를 표시하고 신청 시각·예정일·보관 장소를 안내합니다.
- 물품 새로고침: 목록을 아래로 당겨 다시 조회합니다. 조회 중·실패·빈 결과를 구분합니다. 대여·반납 상태는 API 연결 전까지 현재 앱 기록을 사용합니다.
- 대여 중 전체 건수는 연체를 포함하며, 그래프의 정상 대여 중은 연체를 제외합니다.

일반 계정은 기존 학생 화면을 사용합니다. 대여·반납·공지·물품 변경은 아직 앱 메모리에서 처리하며,
관리자 화면 개편이 해당 기능의 서버 저장 연결 완료를 뜻하지 않습니다.

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

기본 주소는 에뮬레이터용 `http://10.0.2.2:8080`입니다. 팀 서버 주소는 Git에서 제외한 로컬 설정 파일로 전달합니다.
다른 서버를 사용하려면 실행할 때 Backend 기본 주소를 전달합니다.

```powershell
flutter run --dart-define=API_BASE_URL=http://서버주소:포트
```

현재 로컬 코드에는 물품 조회와 회원가입·학번 로그인·로그아웃·관리자 비밀번호 초기화 API 연결이 구현돼 있습니다.
대여·반납·물품 변경·공지는 메모리에서만 처리하며, 알림 설정 저장·푸시·관리자 웹은 미연결 상태입니다.
서버에서 사용하려면 새 인증 코드와 원격 DB 변경을 함께 반영해야 합니다. 로컬 구현과 배포 완료를 구분합니다.

Android Studio 실폰 테스트 시 `mobile` 프로젝트의 Run 설정 → Additional run args에 다음 값을 지정합니다.

```text
--dart-define-from-file=config/local-api.json
```

로컬 설정 파일 형식과 전체 절차는 [DEVELOPMENT.md](DEVELOPMENT.md#android-studio-실폰-테스트)를 확인합니다.
APK 별도 설치 없이 휴대폰을 선택하고 Run으로 실행할 수 있습니다.

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
