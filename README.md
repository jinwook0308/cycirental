# CYCIRENTAL

학과에서 보유하고 있는 대여 물품을 모바일 앱에서 조회하고, 필요한 물품을 예약하며,
자신의 대여 현황과 반납 예정일을 관리할 수 있는 **학과 대여 물품 관리 앱**입니다.

학생이 학과 사무실이나 조교에게 직접 문의하지 않아도 현재 대여 가능한 물품과 수량을 확인하고,
대여 신청부터 반납 일정 확인까지 하나의 서비스에서 처리할 수 있도록 하는 것을 목표로 합니다.

---

## 프로젝트 개요

학과에서는 노트북, 충전기, 카메라, VR 기기, 실습 장비 등 다양한 물품을 학생들에게 대여하고 있습니다.

기존에는 어떤 물품을 대여할 수 있는지, 현재 대여 가능한 수량이 있는지 확인하기 위해
학과 사무실이나 조교에게 직접 문의해야 하는 경우가 많았습니다.

또한 대여 및 반납 현황을 수기나 별도의 문서로 관리할 경우,
현재 어떤 물품이 대여 중인지 빠르게 확인하기 어렵고 반납 예정일을 놓치는 문제도 발생할 수 있습니다.

CYCIRENTAL은 이러한 불편을 개선하기 위해
**물품 조회 → 대여 가능 여부 확인 → 대여 신청 → 대여 현황 확인 → 반납 알림**
과정을 모바일 앱 하나에서 처리할 수 있도록 개발합니다.

---

## 주요 기능

- 로그인 / 회원가입
- 학과 대여 물품 목록 조회
- 물품 검색
- 물품 상세 정보 확인
- 전체 수량 및 대여 가능 수량 확인
- 물품 대여 신청
- 내 대여 현황 확인
- 대여일 및 반납 예정일 확인
- 반납 예정 알림
- 연체 상태 확인

---

## 구현 완료 기능

> 기능 구현이 완료될 때마다 아래 표에 추가합니다.  
> 단순히 기능명만 적지 않고 **담당자, 완료일, 구현 내용, 관련 PR**을 함께 기록합니다.

| 기능 | 담당자 | 완료일 | 구현 내용 | 관련 PR |
|---|---|---|---|---|
| - | - | - | 아직 등록된 완료 기능 없음 | - |

### 작성 예시

```text
| 회원가입 Frontend | 문제혁 | 2026-09-20 | 회원가입 화면 및 입력 폼 구현 | #3 |
| 회원가입 Backend | 김현수 | 2026-09-21 | 회원가입 API 및 중복 이메일 검사 구현 | #5 |
| 회원가입 UI/UX Review | 백진욱 | 2026-09-21 | 입력창 간격 및 버튼 디자인 수정 | #6 |
```

---

## 향후 확장 기능

- QR 코드를 이용한 대여 / 반납 처리
- 관리자용 물품 등록 및 수정 기능
- 물품 고장 및 분실 신고
- 대여 이력 조회
- 학생별 대여 제한 기능

---

## 추천 기술 스택

실제 서비스와 유사한 형태로 개발하기 위해
**모바일 앱 → REST API 서버 → Database → Cloud Server** 구조를 기준으로 개발합니다.

### 전체 서비스 구조

```text
[CYCIRENTAL Mobile App]
        ↓ HTTPS / REST API
[Nginx]
        ↓
[Spring Boot Backend]
        ↓
[MariaDB]
```

배포 시에는 Linux 기반 Cloud Server에서 Backend와 Database를 운영하고,
외부 모바일 기기에서도 실제 서버 주소를 통해 접속할 수 있도록 구성합니다.

---

### Frontend

| 구분 | 추천 기술 / 프로그램 | 용도 |
|---|---|---|
| Framework | Flutter | Android / iOS 모바일 앱 개발 |
| Language | Dart | Flutter 애플리케이션 개발 |
| IDE | Android Studio / VS Code | 모바일 UI 및 기능 개발 |
| API 통신 | Dio 또는 http | Spring Boot REST API 통신 |
| 상태 관리 | Provider 또는 Riverpod | 로그인 상태, 대여 정보 등 앱 상태 관리 |
| UI Design | Figma | UI/UX 화면 설계 및 팀 디자인 공유 |

#### Frontend 추천 구성

```text
Flutter
Dart
Android Studio
VS Code
Figma
Dio
Riverpod
```

Flutter를 사용하면 하나의 코드베이스로 모바일 화면을 구성할 수 있고,
실제 스마트폰에서 APK를 설치하여 시연할 수 있어 실제 서비스 형태의 프로젝트에 적합합니다.

---

### Backend

| 구분 | 추천 기술 / 프로그램 | 용도 |
|---|---|---|
| Framework | Spring Boot | REST API 및 서버 비즈니스 로직 개발 |
| Language | Java 17 또는 Java 21 | Backend 개발 |
| IDE | IntelliJ IDEA | Spring Boot 프로젝트 개발 |
| ORM | Spring Data JPA | Java 객체와 Database 연동 |
| Security | Spring Security | 로그인 및 API 접근 제어 |
| 인증 | JWT | 모바일 앱 사용자 인증 |
| API 문서 | Swagger / OpenAPI | API 명세 및 Frontend 협업 |
| API 테스트 | Postman | Backend API 테스트 |

#### Backend 추천 구성

```text
Java 17 / 21
Spring Boot
Spring Data JPA
Spring Security
JWT
Swagger
Postman
IntelliJ IDEA
```

Backend에서는 로그인, 회원가입, 물품 조회, 물품 검색,
대여 신청, 반납 처리, 대여 상태 관리, 알림 등의 기능을 REST API로 제공합니다.

---

### Database

| 구분 | 추천 기술 / 프로그램 | 용도 |
|---|---|---|
| DBMS | MariaDB | 사용자, 물품, 대여, 반납 데이터 저장 |
| DB 관리 | DataGrip / DBeaver | Database 테이블 및 데이터 관리 |
| ORM 연동 | Spring Data JPA | Spring Boot와 MariaDB 연동 |

#### 주요 테이블 예시

```text
users
items
rentals
rental_history
notifications
```

---

### Server / Deployment

| 구분 | 추천 기술 / 프로그램 | 용도 |
|---|---|---|
| Cloud Server | AWS EC2 | 실제 서비스용 Backend 서버 운영 |
| OS | Ubuntu Server 24.04 LTS | Linux 서버 운영 환경 |
| Web Server / Reverse Proxy | Nginx | 외부 요청을 Spring Boot 서버로 전달 |
| Container | Docker | Backend 및 서비스 실행 환경 통일 |
| Container 관리 | Docker Compose | Spring Boot / MariaDB 컨테이너 관리 |
| HTTPS | Let's Encrypt | HTTPS 인증서 적용 |
| CI/CD | GitHub Actions | GitHub Push / Merge 후 자동 빌드 및 배포 |
| 원격 서버 관리 | SSH / Xshell | 서버 접속 및 로그 확인 |

#### Server 추천 구성

```text
AWS EC2
Ubuntu Server 24.04 LTS
Nginx
Docker
Docker Compose
Let's Encrypt
GitHub Actions
```

개발 단계에서는 각 담당자의 PC에서 Spring Boot와 MariaDB를 실행하여 테스트하고,
최종 통합 단계에서는 AWS EC2 서버에 배포하여 실제 모바일 기기가 인터넷을 통해
CYCIRENTAL 서버에 접속할 수 있도록 구성합니다.

---

### 최종 추천 기술 스택

```text
Frontend
├─ Flutter
├─ Dart
├─ Android Studio / VS Code
├─ Dio
├─ Riverpod
└─ Figma

Backend
├─ Java 17 / 21
├─ Spring Boot
├─ Spring Data JPA
├─ Spring Security
├─ JWT
├─ Swagger
├─ Postman
└─ IntelliJ IDEA

Database
├─ MariaDB
└─ DataGrip / DBeaver

Server
├─ AWS EC2
├─ Ubuntu Server 24.04 LTS
├─ Nginx
├─ Docker
├─ Docker Compose
├─ Let's Encrypt
└─ GitHub Actions

Collaboration
├─ Git
└─ GitHub
```

### 실제 서비스 배포 구조

```text
┌──────────────────────────────┐
│       CYCIRENTAL APP         │
│        Flutter / Dart        │
└──────────────┬───────────────┘
               │
               │ HTTPS
               ▼
┌──────────────────────────────┐
│          AWS EC2             │
│     Ubuntu Server 24.04      │
│                              │
│  ┌────────────────────────┐  │
│  │         Nginx          │  │
│  └───────────┬────────────┘  │
│              ▼               │
│  ┌────────────────────────┐  │
│  │     Spring Boot        │  │
│  │      REST API          │  │
│  └───────────┬────────────┘  │
│              ▼               │
│  ┌────────────────────────┐  │
│  │       MariaDB          │  │
│  └────────────────────────┘  │
└──────────────────────────────┘
```

---


# GitHub 협업 규칙

## 1. 브랜치 구조

```text
main
├─ front-dev
│  ├─ front/auth
│  ├─ front/home
│  ├─ front/items
│  ├─ front/rental
│  └─ front/my-rental
│
└─ back-dev
   ├─ back/auth
   ├─ back/items
   ├─ back/rental
   └─ back/notification
```

### 브랜치 역할

#### `main`

- 최종 통합 브랜치
- 직접 기능 개발 금지
- `front-dev`, `back-dev`에서 검토가 완료된 코드만 반영
- 실제 실행 및 제출 기준이 되는 안정화 브랜치

#### `front-dev`

- Frontend 통합 브랜치
- `front/*` 기능 브랜치 작업 완료 후 PR을 통해 반영
- Frontend 기능 간 충돌 및 화면 연결 확인

#### `back-dev`

- Backend 통합 브랜치
- `back/*` 기능 브랜치 작업 완료 후 PR을 통해 반영
- API, Database 연동 및 Backend 기능 통합 확인

#### 기능 브랜치

기능 단위로 생성합니다.

```text
Frontend: front/기능명
Backend : back/기능명
```

> **브랜치 생성 규칙**
>
> 모든 브랜치는 `main`을 기준으로 생성합니다.  
> `front-dev` 또는 `back-dev` 안에서 각 부분 별 브랜치 생성  


---

## 2. 기능 브랜치 예시

### Frontend

```text
front/auth        로그인 / 회원가입
front/home        홈 화면
front/items       물품 목록 / 검색 / 상세
front/rental      대여 신청
front/my-rental   내 대여 현황
```

### Backend

```text
back/auth          로그인 / 회원가입 / 사용자 인증
back/items         물품 조회 / 검색 / 수량 관리
back/rental        대여 신청 / 반납 / 대여 상태 관리
back/notification  반납 예정 / 연체 알림
```

### 브랜치 생성 예시

```bash
git checkout front-dev
git pull origin front-dev
git checkout -b front/auth
```

Backend 작업의 경우:

```bash
git checkout back-dev
git pull origin back-dev
git checkout -b back/auth
```

---

## 3. Commit 규칙

Commit 메시지는 아래 형식을 사용합니다.

```text
feat: 새로 추가한 내용
fix: 오류 및 버그 수정
update: 기존 내용 수정 및 기능 개선
```

### `feat`

새로운 기능, 폴더 또는 파일을 추가했을 때 사용합니다.

```text
feat: 회원가입 페이지 추가
feat: 물품 목록 화면 추가
feat: 회원가입 API 추가
feat: rental 테이블 생성
feat: 반납 예정일 알림 기능 추가
```

### `fix`

오류 또는 버그를 수정했을 때 사용합니다.

```text
fix: 회원가입 버튼 클릭 오류 수정
fix: 이메일 중복 검사 오류 수정
fix: 대여 가능 수량이 음수로 표시되는 오류 수정
fix: 로그인 실패 시 잘못된 화면으로 이동하는 오류 수정
```

### `update`

기존 기능이나 화면을 수정하거나 개선했을 때 사용합니다.

```text
update: 회원가입 입력창 간격 및 버튼 크기 수정
update: 물품 상세 화면 레이아웃 수정
update: 대여 신청 로직 개선
update: 데이터베이스 컬럼 구조 수정
```

### Commit 작성 원칙

수정 및 추가 내용은 최대한 구체적으로 작성합니다.

```text
X update: 수정
X fix: 오류 수정

O update: 회원가입 입력창 간격 및 버튼 크기 수정
O fix: 이메일 중복 검사 시 잘못된 결과가 출력되는 오류 수정
```

한 Commit에는 가능한 한 하나의 작업 목적만 포함합니다.

---

## 4. Pull Request 규칙

기능 브랜치 작업 완료 후 해당 통합 브랜치로 Pull Request를 생성합니다.

```text
front/* → front-dev
back/*  → back-dev
```

파트별 기능 검토 및 통합이 완료되면 최종적으로 `main`에 반영합니다.

```text
front-dev → main
back-dev  → main
```

### PR 제목 규칙

```text
담당자(이름) - 작업 내용
```

### PR 제목 예시

```text
백진욱 - 회원가입 UI/UX 디자인 수정
문제혁 - 로그인 및 회원가입 Frontend 구현
김현수 - 회원가입 Backend API 구현
이재원 - 대여 기능 Backend 구현
```

### PR 본문 작성 형식

```md
## 작업 내용

- 회원가입 화면 구현
- 이름 / 학번 / 이메일 입력 UI 추가
- 비밀번호 확인 기능 추가

## 수정 / 추가된 파일

- SignupPage
- SignupForm
- signup.css

## 확인 사항

- 회원가입 화면 정상 출력 확인
- 입력값 검증 확인
- 모바일 화면 레이아웃 확인

## 추가 확인이 필요한 내용

- Backend 회원가입 API 연결 필요
```

PR 생성 후 바로 Merge하지 않고 **코드 리뷰를 진행한 뒤 이상이 없을 경우 Merge**합니다.

---

## 5. Code Review 규칙

### Frontend

- UI/UX 디자인 및 전체 화면 검토: **백진욱**
- Frontend 코드 및 구조 검토: **문제혁**

### Backend

- Backend 기능은 **김현수 / 이재원**이 상호 검토
- Database 구조 또는 DB 연동 변경이 포함될 경우 **백진욱**에게 공유
- Frontend와 연결되는 API는 Frontend 담당자와 함께 통합 테스트

### Review 시 확인 사항

- 기능이 정상적으로 동작하는지
- 기존 기능에 오류가 발생하지 않는지
- 중복 코드가 과도하게 발생하지 않았는지
- 변수명 / 파일명 / 함수명이 역할을 이해할 수 있도록 작성되었는지
- 불필요한 파일이 Commit되지 않았는지
- UI가 전체 디자인 방향과 일치하는지
- API 요청 / 응답 형식이 Frontend와 일치하는지
- Database 변경 사항이 다른 기능에 영향을 주지 않는지

---

## 6. 작업 흐름

### Frontend

```text
front/기능
↓
개발
↓
Commit
↓
Push
↓
Pull Request
↓
Code Review
↓
수정사항 반영
↓
front-dev Merge
↓
Frontend 통합 확인
↓
main Merge
```

### Backend

```text
back/기능
↓
개발
↓
Commit
↓
Push
↓
Pull Request
↓
Code Review
↓
수정사항 반영
↓
back-dev Merge
↓
Backend 통합 확인
↓
main Merge
```

---

## 7. 팀원 담당

### 백진욱

- 프로젝트 총괄
- 전체 디자인 총괄
- UI/UX 리뷰
- Database 담당
- Frontend / Backend 통합 진행 상황 확인
- Pull Request 및 전체 프로젝트 구조 확인

### 문제혁

- UI/UX 개발
- Frontend 개발
- Frontend 총괄
- Frontend 코드 리뷰
- Frontend 기능 통합

### 김현수

- Backend 개발
- API 개발
- Database 연동
- Backend 코드 리뷰

### 이재원

- Backend 개발
- API 개발
- Database 연동
- Backend 코드 리뷰

---

## 8. 공통 개발 규칙

1. `main` 브랜치에서 직접 기능 개발하지 않습니다.
2. **새 브랜치는 항상 `main`을 기준으로 생성하며, 브랜치 안에서 또 다른 브랜치를 생성하지 않습니다.**
3. 모든 작업 브랜치는 `main`과 동일한 상위 수준에서 관리합니다.
4. Frontend는 `front/*`, Backend는 `back/*` 기능 브랜치에서 작업합니다.
5. 작업 시작 전 `main` 브랜치를 최신 상태로 업데이트한 뒤 작업 브랜치를 생성합니다.
6. Frontend 기능은 검토 후 `front-dev`에 반영하고, Backend 기능은 검토 후 `back-dev`에 반영합니다.
7. Commit 메시지는 `feat`, `fix`, `update` 규칙을 사용합니다.
8. Commit 메시지에는 실제 수정한 내용을 구체적으로 작성합니다.
9. 기능 구현 완료 후 Pull Request를 생성합니다.
10. Pull Request 생성 후 코드 리뷰 없이 바로 Merge하지 않습니다.
11. 다른 담당자의 코드를 수정할 경우 해당 담당자에게 변경 내용을 공유합니다.
12. Frontend와 Backend가 연결되는 기능은 주기적으로 통합 테스트합니다.
13. Database 구조를 변경할 경우 Backend 담당자에게 변경 내용을 공유합니다.
14. Merge 전 충돌 여부와 프로그램 정상 실행 여부를 확인합니다.
15. 기능 구현이 완료되면 README의 **구현 완료 기능** 항목을 함께 업데이트합니다.

---

## 9. 구현 완료 기능 업데이트 규칙

기능 구현이 완료되어 통합 브랜치에 Merge된 경우 README의
**구현 완료 기능** 표를 업데이트합니다.

### 작성 기준

- 실제 구현이 끝난 기능만 작성
- 개발 중인 기능은 작성하지 않음
- 담당자 이름 작성
- 완료 날짜 작성
- 핵심 구현 내용을 간단하면서도 구체적으로 작성
- 가능하면 관련 Pull Request 번호 작성

### 예시

```text
| 로그인 Frontend | 문제혁 | 2026-09-25 | 로그인 화면 및 입력값 검증 구현 | #8 |
| 로그인 Backend | 김현수 | 2026-09-25 | 로그인 API 및 사용자 인증 구현 | #10 |
| 로그인 UI/UX Review | 백진욱 | 2026-09-26 | 로그인 화면 간격 및 버튼 디자인 개선 | #11 |
```

---


## 11. 프로젝트 기본 동작 흐름

```text
학생 로그인
↓
대여 물품 목록 확인
↓
필요한 물품 검색 / 선택
↓
물품 상세 정보 확인
↓
현재 대여 가능 수량 확인
↓
대여 신청
↓
대여 완료
↓
내 대여 현황 확인
↓
반납 예정일 알림
↓
물품 반납
↓
대여 완료 처리
```

---

## 12. 팀 개발 원칙

> 기능 구현 자체뿐만 아니라 팀원이 코드를 이해하고 검토할 수 있도록  
> Commit과 Pull Request에 작업 내용을 구체적으로 기록합니다.

> `main`은 항상 실행 가능한 상태를 유지하며,  
> 검토가 끝나지 않은 기능은 직접 Merge하지 않습니다.
