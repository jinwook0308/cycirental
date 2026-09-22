# DeptRental Windows 개발 환경 설정 가이드

팀원이 새 Windows PC에서 DeptRental을 실행할 때 사용하는 문서입니다. 이번 초기 설정에서 실제로 발생했던 오류와 해결 방법도 함께 정리했습니다.

> 가장 중요한 점: 프로젝트는 `C:\dev\cycirental`처럼 **한글과 OneDrive가 없는 짧은 영문 경로**에 받으세요. 한글 경로에서는 Flutter 테스트가 통과해도 Android Gradle 빌드가 실패할 수 있습니다.

## 1. 프로그램별 용도

| 프로그램 | 용도 | 열어야 하는 폴더 |
| --- | --- | --- |
| Git | GitHub 저장소 복제 및 공동 작업 | 저장소 전체 |
| Flutter SDK | 모바일 앱 개발 도구 | 명령어에서 사용 |
| Android Studio | Flutter 앱 편집, Android SDK 및 에뮬레이터 실행 | `cycirental\mobile` |
| JDK 21 | Spring Boot 백엔드 실행 | 명령어에서 사용 |
| IntelliJ IDEA | Spring Boot 백엔드 편집 및 실행 | `cycirental\backend` |
| DBeaver Community | 원격 MariaDB 조회 및 관리 | 별도 DB 연결 생성 |

MariaDB 서버 프로그램은 모든 팀원 PC에 설치할 필요가 없습니다. 팀 공용 원격 DB를 사용할 때는 DBeaver만 설치하면 됩니다.

## 2. 프로그램 설치 순서

아래 순서대로 설치하는 것을 권장합니다.

1. [Git for Windows](https://git-scm.com/download/win)
2. [Flutter SDK](https://docs.flutter.dev/install/manual)
3. [Android Studio](https://developer.android.com/studio)
4. [Eclipse Temurin JDK 21](https://adoptium.net/temurin/releases/?version=21)
5. [IntelliJ IDEA](https://www.jetbrains.com/idea/download/)
6. [DBeaver Community](https://dbeaver.io/download/)

### Flutter 설치 위치

Flutter ZIP 파일은 다음과 같이 한글과 공백이 없는 경로에 압축을 풉니다.

```text
C:\dev\flutter
```

Windows 사용자 환경 변수 `Path`에 다음 경로를 추가합니다.

```text
C:\dev\flutter\bin
```

새 PowerShell을 열고 설치를 확인합니다.

```powershell
flutter --version
flutter doctor -v
```

이 PC에서 사용한 버전은 Flutter 3.47.5, Dart 3.13.4입니다. Flutter에는 Dart SDK가 포함되어 있으므로 Dart를 별도로 내려받지 않아도 됩니다.

### Android Studio 플러그인

Android Studio에서 다음 메뉴를 엽니다.

```text
File > Settings > Plugins > Marketplace
```

`Flutter`를 검색하여 설치합니다. Dart 플러그인도 함께 설치 또는 활성화되는지 확인한 뒤 Android Studio를 다시 시작합니다.

### Android SDK

Android Studio에서 다음 메뉴를 엽니다.

```text
File > Settings > Languages & Frameworks > Android SDK
```

다음을 설치합니다.

- Android SDK Platform 35 또는 36
- Android SDK Build-Tools
- Android SDK Platform-Tools
- Android Emulator
- Android SDK Command-line Tools (latest)

라이선스가 남아 있으면 PowerShell에서 다음 명령을 실행하고 모두 동의합니다.

```powershell
flutter doctor --android-licenses
```

### JDK 21

Temurin 설치 관리자에서 가능하면 다음 항목을 선택합니다.

- `JAVA_HOME` 환경 변수 설정
- Java 실행 파일을 `Path`에 추가

새 PowerShell에서 확인합니다.

```powershell
java -version
```

21 버전이 표시되면 됩니다. Android Studio의 Android 빌드는 기본 내장 JBR을 사용해도 되고, JDK 21은 주로 백엔드에 사용합니다.

## 3. GitHub에서 프로젝트 받기

PowerShell을 관리자 권한 없이 열고 다음 명령을 실행합니다.

```powershell
New-Item -ItemType Directory -Force C:\dev
git clone https://github.com/jinwook0308/cycirental.git C:\dev\cycirental
cd C:\dev\cycirental
git switch main
```

이미 받은 프로젝트를 최신 상태로 갱신할 때는 다음 명령을 사용합니다.

```powershell
cd C:\dev\cycirental
git pull origin main
```

## 4. 모바일 앱을 Android Studio에서 실행하기

### 프로젝트 열기

Android Studio 시작 화면에서 `Open`을 누르고 다음 폴더를 선택합니다.

```text
C:\dev\cycirental\mobile
```

저장소 루트 `cycirental`이나 `mobile\android`만 열지 마세요. 반드시 Flutter 프로젝트인 `mobile` 폴더를 엽니다.

오른쪽 아래의 인덱싱과 의존성 다운로드가 끝날 때까지 기다린 뒤 Android Studio 터미널에서 실행합니다.

```powershell
flutter pub get
flutter doctor -v
```

### Android 에뮬레이터 만들기

1. `Tools > Device Manager`를 엽니다.
2. `+` 또는 `Create Virtual Device`를 누릅니다.
3. `Phone`에서 Pixel 계열 기기를 고릅니다.
4. API 35 또는 36의 `Google APIs x86_64` 시스템 이미지를 선택합니다.
5. 이미지 옆에 다운로드 아이콘이 있으면 먼저 내려받습니다.
6. 설치가 끝난 후 `Finish`를 누릅니다.
7. Device Manager의 재생 버튼으로 에뮬레이터를 켭니다.

에뮬레이터가 홈 화면까지 완전히 켜지면 Android Studio 상단 장치 목록에서 Android 기기를 선택합니다. `Windows (desktop)`를 선택하면 안 됩니다.

### 앱 실행

왼쪽 프로젝트 창에서 `lib/main.dart`를 열고 상단의 초록색 실행 버튼을 누릅니다. 터미널에서는 다음처럼 실행할 수 있습니다.

```powershell
cd C:\dev\cycirental\mobile
flutter devices
flutter run
```

첫 실행은 Gradle, NDK 및 Android 의존성을 내려받으므로 시간이 오래 걸릴 수 있습니다. 실행 후에는 `r`로 Hot Reload, `R`로 Hot Restart, `q`로 종료할 수 있습니다.

현재 모바일 데모의 데이터는 메모리에만 저장되므로 앱을 완전히 다시 시작하면 초기화됩니다. 아직 백엔드나 MariaDB와 연결된 버전은 아닙니다.

## 5. 백엔드를 IntelliJ IDEA에서 실행하기

1. IntelliJ IDEA에서 `Open`을 누릅니다.
2. `C:\dev\cycirental\backend` 폴더를 선택합니다.
3. 프로젝트 SDK로 JDK 21을 선택합니다.
4. Maven 의존성 불러오기가 끝날 때까지 기다립니다.
5. `DeptRentalApiApplication`의 실행 버튼을 누릅니다.

PowerShell에서 실행해도 됩니다.

```powershell
cd C:\dev\cycirental\backend
.\mvnw.cmd spring-boot:run
```

기본 설정은 안전한 H2 인메모리 DB를 사용하며 백엔드는 `127.0.0.1:8080`에서 실행됩니다.

확인 주소:

- `http://127.0.0.1:8080/api/health`
- `http://127.0.0.1:8080/api/items`
- `http://127.0.0.1:8080/api/items?query=VR`

Android 에뮬레이터에서 PC의 백엔드로 접근할 때는 `127.0.0.1` 대신 `10.0.2.2:8080`을 사용합니다.

## 6. DBeaver에서 원격 MariaDB 연결하기

DB 주소, 포트, DB 이름, 계정, 비밀번호는 GitHub나 단체 채팅에 공개하지 말고 팀 관리자에게 개인적으로 받습니다.

1. DBeaver를 실행합니다.
2. `Database > New Database Connection`을 선택합니다.
3. `MariaDB`를 선택합니다.
4. 팀에서 받은 `Host`, `Port`, `Database`, `Username`, `Password`를 입력합니다.
5. `Test Connection`을 누릅니다.
6. 드라이버 다운로드 창이 뜨면 허용합니다.
7. 테스트가 성공하면 `Finish`를 누릅니다.

연결 옆 빨간 X 표시는 보통 아직 연결되지 않았거나 연결 시험에 실패했다는 뜻입니다. 연결을 더블클릭하고 나타나는 정확한 오류 메시지를 확인하세요.

- `Connection timed out`: 서버, 포트, 방화벽, 허용 IP 또는 VPN 확인
- `Access denied`: 사용자명, 비밀번호, 계정의 허용 호스트 확인
- `Unknown database`: DB 이름 확인
- `Connection refused`: MariaDB 실행 상태와 서버의 외부 접속 설정 확인

같은 이름의 연결이 두 개 보이면 DB가 두 개 생긴 것이 아니라 DBeaver 연결 설정을 두 번 만든 것입니다. 불필요한 연결 설정만 삭제해도 실제 DB는 삭제되지 않습니다.

### 백엔드를 MariaDB 프로필로 실행하기

`backend/.env.example`은 필요한 변수 이름을 보여 주는 예시입니다. Spring Boot가 `.env` 파일을 자동으로 읽는 것은 아니므로, IntelliJ 실행 설정의 `Environment variables`에 입력하거나 현재 PowerShell 세션에 설정해야 합니다.

```powershell
$env:SPRING_PROFILES_ACTIVE = "mariadb"
$env:DB_HOST = "팀에서 받은 호스트"
$env:DB_PORT = "3306"
$env:DB_NAME = "팀에서 받은 DB 이름"
$env:DB_USER = "팀에서 받은 사용자"
$env:DB_PASSWORD = "팀에서 받은 비밀번호"
.\mvnw.cmd spring-boot:run
```

실제 비밀번호가 든 `.env` 파일은 `.gitignore` 처리되어 있으며 절대로 Git에 추가하면 안 됩니다. 원격 DB 구조를 확인하기 전까지 자동 테이블 생성과 Flyway 실행도 비활성화되어 있습니다.

## 7. 이번에 발생한 오류와 해결 방법

### 상단에 Run 버튼이나 실행 구성이 없음

원인은 대체로 Flutter/Dart 플러그인이 없거나 Flutter 프로젝트 폴더를 잘못 연 경우입니다.

1. Flutter 및 Dart 플러그인을 설치하고 Android Studio를 다시 시작합니다.
2. 현재 창을 닫고 `C:\dev\cycirental\mobile`을 다시 엽니다.
3. `lib/main.dart`를 엽니다.
4. 그래도 없으면 `File > Settings > Languages & Frameworks > Flutter`에서 Flutter SDK 경로를 `C:\dev\flutter`로 지정합니다.

### `Dart SDK is not configured`

`Open Dart settings`를 누르거나 다음 메뉴로 이동합니다.

```text
File > Settings > Languages & Frameworks > Dart
```

다음과 같이 설정합니다.

- `Enable Dart support for the project` 체크
- `mobile` 모듈 체크
- Dart SDK path: `C:\dev\flutter\bin\cache\dart-sdk`

`Apply`와 `OK`를 누릅니다. Dart를 별도로 설치할 필요는 없습니다.

### 실행 창에 `Windows SDK` 또는 `main.dart (Windows)`가 표시됨

Android가 아니라 Windows 데스크톱 대상으로 실행한 것입니다.

1. 실행을 중지합니다.
2. Device Manager에서 Android 에뮬레이터를 켭니다.
3. 상단 장치 목록에서 `sdk gphone...` 또는 자신이 만든 Android 기기를 선택합니다.
4. 다시 실행합니다.

### Device Manager에 `Missing system image`가 표시됨

해당 가상 기기가 사용하는 Android 시스템 이미지가 설치되지 않은 상태입니다.

1. 가상 기기 오른쪽 다운로드 아이콘을 누릅니다.
2. 다운로드와 설치가 완전히 끝날 때까지 기다립니다.
3. 계속 실패하면 기존 가상 기기를 삭제하고 API 35 또는 36의 `Google APIs x86_64` 이미지로 새로 만듭니다.

인터넷 연결이 필요하며, Android Studio를 다시 켜기만 해서는 해결되지 않습니다. 시스템 이미지 다운로드를 끝내야 합니다.

### 에뮬레이터가 느리거나 시작되지 않음

- 작업 관리자 `성능 > CPU`에서 `가상화: 사용`인지 확인합니다.
- BIOS/UEFI에서 CPU 가상화를 켭니다.
- Windows 기능에서 `Windows Hypervisor Platform`을 켜고 재부팅합니다.
- Android Studio SDK Tools에서 Android Emulator가 최신인지 확인합니다.

Android 공식 문서는 Windows Hypervisor Platform 사용을 권장합니다. 기존 Android Emulator Hypervisor Driver는 2026년 말 지원 종료 예정이므로 새 PC는 WHPX를 사용하는 편이 좋습니다.

### 첫 실행에서 빨간 Java 경고가 표시됨

다음과 비슷한 문구는 현재 Gradle/Java 조합에서 나오는 경고이며 그 자체로 빌드 실패는 아닙니다.

```text
WARNING: A restricted method in java.lang.System has been called
```

또한 아래 문구도 첫 설치에서 정상적으로 나타날 수 있습니다.

```text
Running Gradle task 'assembleDebug'...
Checking the licenses for package NDK...
```

다운로드가 끝날 때까지 기다리세요. 실제 문제는 마지막에 `FAILURE: Build failed` 또는 `Error`가 나타날 때입니다.

### `packages have newer versions incompatible with dependency constraints`

새 버전이 있다는 안내일 뿐 오류가 아닙니다. 팀의 버전을 맞추기 위해 임의로 `flutter pub upgrade --major-versions`를 실행하지 말고 현재 설정 그대로 진행합니다.

### Gradle 빌드 또는 JVM이 이유 없이 종료됨

프로젝트 경로에 한글, 특수문자, 긴 OneDrive 경로가 있는지 확인합니다. 이번 설정에서도 OneDrive의 `문서` 경로에서는 APK 빌드가 실패했고 영문 경로에서는 성공했습니다.

```text
권장: C:\dev\cycirental
비권장: C:\Users\이름\OneDrive\문서\cycirental
```

파일을 수동 복사하지 말고 권장 경로에 저장소를 다시 `git clone`하세요.

## 8. 정상 설치 확인 명령

모바일:

```powershell
cd C:\dev\cycirental\mobile
flutter doctor -v
flutter devices
flutter pub get
dart analyze lib test
flutter test
flutter build apk --debug
```

백엔드:

```powershell
cd C:\dev\cycirental\backend
java -version
.\mvnw.cmd test
```

`flutter doctor -v`에서 Android toolchain과 Android Studio가 정상 표시되고, 분석·테스트·APK 빌드와 백엔드 테스트가 모두 통과하면 준비가 끝난 것입니다.

## 9. 문제가 생겼을 때 공유할 정보

비밀번호를 제외하고 다음 정보를 팀에 보내면 문제를 빨리 찾을 수 있습니다.

- 오류가 보이는 전체 화면 캡처
- 터미널의 마지막 오류 부분
- `flutter doctor -v` 결과
- `flutter devices` 결과
- 프로젝트를 받은 실제 경로
- Android Studio에서 선택한 실행 장치 이름

DB 화면을 캡처할 때는 반드시 비밀번호를 가리고, 공용 저장소나 단체 채팅에 실제 비밀번호를 올리지 마세요.

## 참고 문서

- [Flutter Android 설정](https://docs.flutter.dev/platform-integration/android/setup)
- [Flutter용 Android Studio 사용법](https://docs.flutter.dev/tools/android-studio)
- [Android 가상 기기 관리](https://developer.android.com/studio/run/managing-avds)
- [Android Emulator 가속 설정](https://developer.android.com/studio/run/emulator-acceleration)
- [IntelliJ IDEA JDK 설정](https://www.jetbrains.com/help/idea/sdk.html)
- [DBeaver MariaDB 연결](https://dbeaver.com/docs/dbeaver/Database-driver-MariaDB/)
