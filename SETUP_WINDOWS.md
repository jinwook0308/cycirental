# CYCIRENTAL Windows 개발 환경 설정

Windows PC에서 CYCIRENTAL Frontend를 실행하기 위한 기본 개발 환경 설정 문서입니다.

> 프로젝트는 `C:\dev\cycirental`처럼 **한글과 OneDrive가 없는 짧은 영문 경로**에 받는 것을 권장합니다.

---

## 1. 필요한 프로그램

| 프로그램 | 용도 |
| --- | --- |
| Git | GitHub 저장소 복제 및 공동 작업 |
| Flutter SDK | Flutter 앱 개발 |
| Android Studio | Flutter 편집, Android SDK 및 Emulator |
| VS Code | 선택적으로 사용하는 코드 편집기 |

Backend 개발에 필요한 JDK, IntelliJ, DBeaver 등은
[Backend 저장소](https://github.com/cycirental-team/cycirental-backend)의 안내를 기준으로 합니다.

---

## 2. Flutter 설치

Flutter SDK는 한글과 공백이 없는 경로에 설치하는 것을 권장합니다.

예시:

```text
C:\dev\flutter
```

Windows 환경 변수 `Path`에 다음 경로를 추가합니다.

```text
C:\dev\flutter\bin
```

새 PowerShell을 열고 확인합니다.

```powershell
flutter --version
flutter doctor -v
```

Flutter에는 Dart SDK가 포함되어 있으므로 Dart를 별도로 설치할 필요는 없습니다.

---

## 3. Android Studio 설정

Android Studio에서 Flutter 플러그인을 설치합니다.

```text
File > Settings > Plugins > Marketplace
```

`Flutter`를 검색하여 설치합니다.

필요한 Android SDK 구성 요소도 설치합니다.

- Android SDK Platform
- Android SDK Build-Tools
- Android SDK Platform-Tools
- Android Emulator
- Android SDK Command-line Tools

라이선스가 남아 있으면 다음 명령을 실행합니다.

```powershell
flutter doctor --android-licenses
```

---

## 4. 저장소 받기

```powershell
New-Item -ItemType Directory -Force C:\dev

git clone https://github.com/jinwook0308/cycirental.git C:\dev\cycirental

cd C:\dev\cycirental
```

Backend가 필요한 경우 별도로 다음 저장소를 사용합니다.

```text
https://github.com/cycirental-team/cycirental-backend
```

---

## 5. Flutter 프로젝트 열기

Android Studio에서 다음 폴더를 엽니다.

```text
C:\dev\cycirental\mobile
```

저장소 루트 `cycirental`이나 `mobile\android`만 열지 않고
Flutter 프로젝트 루트인 `mobile` 폴더를 엽니다.

의존성을 설치합니다.

```powershell
cd C:\dev\cycirental\mobile
flutter pub get
```

---

## 6. Android Emulator

Android Studio에서:

```text
Tools > Device Manager
```

를 열고 Android 가상 기기를 생성합니다.

Emulator가 완전히 실행된 뒤 다음 명령으로 연결 상태를 확인합니다.

```powershell
flutter devices
```

---

## 7. 앱 실행

```powershell
cd C:\dev\cycirental\mobile
flutter run
```

Android Studio에서는 `lib/main.dart`를 열고 Android 기기를 선택한 뒤 실행할 수 있습니다.

---

## 8. Backend 연결

로컬 Backend 기본 포트는 `8080`입니다.

Android Emulator에서 개발 PC에 실행 중인 Backend로 접근할 때는:

```text
http://10.0.2.2:8080
```

을 사용합니다.

Backend 실행, MariaDB, 서버 및 자동 배포 관련 내용은
[Backend 저장소](https://github.com/cycirental-team/cycirental-backend)의 README를 확인합니다.

---

## 9. 자주 발생하는 문제

### Run 버튼 또는 Flutter 실행 구성이 보이지 않음

- Flutter / Dart 플러그인 설치 여부 확인
- Android Studio에서 `mobile` 폴더를 열었는지 확인
- `lib/main.dart`를 열었는지 확인

---

### `Dart SDK is not configured`

Flutter SDK 내부 Dart SDK 경로를 사용합니다.

예시:

```text
C:\dev\flutter\bin\cache\dart-sdk
```

---

### Android 기기 대신 Windows가 선택됨

Device Manager에서 Android Emulator를 실행한 뒤
Android Studio 상단 기기 선택에서 Android 기기를 선택합니다.

---

### Gradle 빌드 또는 JVM이 이유 없이 종료됨

프로젝트 경로에 한글, 특수문자 또는 긴 OneDrive 경로가 있는지 확인합니다.

권장:

```text
C:\dev\cycirental
```

비권장:

```text
C:\Users\이름\OneDrive\문서\cycirental
```

---

## 10. 정상 설치 확인

```powershell
cd C:\dev\cycirental\mobile

flutter doctor -v
flutter devices
flutter pub get
dart analyze lib
flutter test
flutter build apk --debug
```

Android toolchain과 Android Studio가 정상 표시되고,
분석·테스트·APK 빌드가 통과하면 Frontend 개발 준비가 완료된 것입니다.

---

## 관련 문서

- [Frontend README](README.md)
- [Frontend 개발 안내](DEVELOPMENT.md)
- [공통 협업 규칙](CONTRIBUTING.md)
- [팀원 역할 및 담당](TEAM.md)
- [Backend 저장소](https://github.com/cycirental-team/cycirental-backend)
