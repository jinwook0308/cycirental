# DeptRental 개발 시작 안내

기존 `README.md`는 팀에서 제공한 원문을 그대로 유지합니다. 이 문서는 새 기본 뼈대의 실행 방법만 설명합니다.

처음 개발 환경을 설치하는 팀원은 [Windows 개발 환경 설정 및 오류 해결 가이드](SETUP_WINDOWS.md)를 먼저 따라 하세요.

## 현재 구현 범위

- `mobile/`: Flutter + Android Studio용 앱. 컨셉아트의 남색/파란색 톤과 로그인 → 홈 → 물품 목록·검색 → 상세·신청 → 내 대여·반납 → 알림 흐름을 반영했습니다. 기본 예시 대여 내역이 있어 모든 화면을 바로 시연할 수 있습니다.
- `backend/`: Java 21 + Spring Boot 읽기 전용 물품 API (`GET /api/health`, `GET /api/items`, `GET /api/items/{id}`, `GET /api/items?query=VR`).
- 기본 실행은 H2 인메모리 DB의 데모 데이터입니다. 앱 대여 신청 역시 메모리에만 저장됩니다. 실제 인증, 대여 트랜잭션, 푸시 알림은 아직 구현되지 않았습니다.

## 개발 도구

- 이 PC에는 Android Studio, Flutter SDK, Android SDK 36, JDK 21, IntelliJ IDEA, DBeaver Community와 Android Studio의 Flutter/Dart 플러그인이 설치되었습니다.
- 팀원 PC에서도 동일한 도구를 설치하고 `flutter doctor`로 환경을 확인하세요.
- 이 PC에는 Android Studio에서 선택할 수 있는 `Medium Phone` Android 가상 기기도 생성했습니다.

## 실행

```powershell
cd mobile
flutter pub get
flutter run
```

```powershell
cd backend
.\mvnw.cmd spring-boot:run
```

Android Studio에서는 `mobile/`, IntelliJ에서는 `backend/`를 각각 프로젝트로 엽니다. 백엔드는 `127.0.0.1:8080`에서만 수신합니다. Android 에뮬레이터에서 PC 백엔드에 접근할 때는 `10.0.2.2:8080`을 사용합니다. 현재 Flutter 앱은 아직 API와 연결되지 않았습니다.

Windows에서 저장소 경로에 한글이 있으면 Android Gradle 빌드가 실패하거나 JVM이 종료될 수 있습니다. 이 PC의 OneDrive `문서` 경로에서는 테스트와 정적 분석은 통과했지만 APK 빌드가 실패했고, 영문 경로의 별도 작업 트리에서는 `flutter build apk --debug`가 성공했습니다. Android Studio 빌드에는 `C:\dev\cycirental`처럼 영문 경로의 체크아웃을 사용하세요.

## 원격 MariaDB 준비

팀이 알려준 주소의 TCP 3306 포트는 이 PC에서 열려 있음을 확인했습니다. 이는 **DB 로그인이나 다른 네트워크에서의 접근 성공을 의미하지 않습니다**. 비밀번호를 받지 못해 실제 계정 권한 및 DB 스키마는 확인하지 않았고, 원격 서버에는 아무 변경도 하지 않았습니다.

백엔드의 `mariadb` 프로필은 `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` 환경변수를 사용합니다. 예시는 `backend/.env.example`에 있으며, 비밀번호가 들어간 실제 `.env` 파일은 Git에 올리지 않습니다. `mariadb` 프로필에서는 안전을 위해 Flyway 자동 실행과 Hibernate 자동 DDL을 꺼 두었습니다. 팀 DB의 기존 구조를 확인한 뒤 마이그레이션 적용 여부를 정해야 합니다.

DBeaver 새 연결에서 `MariaDB`를 선택하고 팀의 Host, Port, Database, User를 입력합니다. 비밀번호는 팀 관리자에게 개인적으로 받아 입력하고 Git에 저장하지 않습니다. 가능하면 TLS 인증서 검증을 켜고, 공용 인터넷에 3306을 무제한 개방하지 말고 VPN이나 허용 IP 목록을 사용하세요. 여러 장소에서 접속하려면 서버 관리자에게 계정의 허용 호스트, 방화벽, 공유기/클라우드 인바운드 규칙을 함께 확인받아야 합니다.

## 검증

```powershell
cd mobile
flutter test
dart analyze lib
flutter build apk --debug
```

```powershell
cd backend
.\mvnw.cmd test
```
