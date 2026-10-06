# CYCIRENTAL 협업 규칙

CYCIRENTAL 프로젝트의 공통 Git / GitHub 협업 규칙입니다.

Frontend와 Backend 모두 이 문서를 공통 기준으로 사용합니다.

협업 규칙을 변경할 경우 기존 내용과 충돌하지 않는지 확인하고,
변경 내용을 팀원에게 공유합니다.

---

## 1. 브랜치 구조

### Frontend

```text
main
 ↑
front-dev
 ↑
front/*
```

### Backend

```text
main
 ↑
back-dev
 ↑
back/*
```

---

## 2. 브랜치 역할

### `main`

각 저장소의 최종 안정화 브랜치입니다.

- 직접 기능 개발하지 않습니다.
- 실행 및 제출 기준으로 사용합니다.
- 통합 및 검토가 완료된 `front-dev` 또는 `back-dev`만 반영합니다.

### `front-dev`

Frontend 통합 브랜치입니다.

- `front/*` 작업을 통합합니다.
- Frontend 기능 간 연결을 확인합니다.
- Frontend 작업 브랜치는 이 브랜치를 기준으로 생성합니다.

### `back-dev`

Backend 통합 브랜치입니다.

- `back/*` 작업을 통합합니다.
- API 및 Database 연동을 확인합니다.
- Backend 작업 브랜치는 이 브랜치를 기준으로 생성합니다.

### 작업 브랜치

기능 또는 하나의 작업 목적 단위로 생성합니다.

Frontend:

```text
front/기능명
```

Backend:

```text
back/기능명
```

예시:

```text
front/auth
front/home
front/settings
front/docs-refactor

back/auth
back/items
back/rental
back/docs-refactor
```

다른 작업 브랜치를 기준으로 새로운 작업 브랜치를 생성하지 않습니다.

---

## 3. 작업 흐름

### Frontend

```text
front-dev 최신화
        ↓
front/* 브랜치 생성
        ↓
개발 / 수정
        ↓
Commit / Push
        ↓
Pull Request
        ↓
Code Review
        ↓
front-dev Merge
        ↓
Frontend 통합 확인
        ↓
main Merge
```

### Backend

```text
back-dev 최신화
        ↓
back/* 브랜치 생성
        ↓
개발 / 수정
        ↓
Commit / Push
        ↓
Pull Request
        ↓
Code Review
        ↓
back-dev Merge
        ↓
Backend 통합 확인
        ↓
main Merge
```

---

## 4. Commit 규칙

Commit 메시지는 다음 형식을 사용합니다.

```text
feat: 새 기능 또는 파일 추가
fix: 오류 및 버그 수정
update: 기존 내용 수정 및 기능 개선
```

예시:

```text
feat: 회원가입 페이지 추가
feat: 대여 API 추가
fix: 로그인 실패 시 화면 이동 오류 수정
update: 홈 화면 공지사항 배치 수정
update: README 구조 정리
```

Commit 메시지에는 실제 변경 내용을 가능한 한 구체적으로 작성합니다.

한 Commit에는 가능한 한 하나의 작업 목적만 포함합니다.

---

## 5. Pull Request 규칙

작업 브랜치에서 바로 `main`으로 Merge하지 않습니다.

Frontend:

```text
front/* → front-dev
front-dev → main
```

Backend:

```text
back/* → back-dev
back-dev → main
```

PR 제목은 다음 형식을 사용합니다.

```text
담당자 이름 - 작업 내용
```

예시:

```text
백진욱 - Frontend README 및 협업 문서 정리
문제혁 - 로그인 화면 구현
김현수 - 회원가입 API 구현
이재원 - 대여 API 수정
```

PR 본문에는 가능한 한 다음 내용을 작성합니다.

```md
## 작업 내용

- 변경하거나 추가한 내용

## 수정 / 추가된 파일

- 변경한 주요 파일

## 확인 사항

- 직접 확인한 기능 또는 테스트

## 추가 확인이 필요한 내용

- 다른 담당자와 확인이 필요한 내용
```

---

## 6. Code Review 규칙

Merge 전에 다음 내용을 확인합니다.

- 기능이 정상적으로 동작하는지
- 기존 기능에 오류가 발생하지 않는지
- 불필요한 파일이 포함되지 않았는지
- 변수명, 파일명, 함수명이 역할을 이해할 수 있도록 작성되었는지
- UI가 전체 디자인 방향과 일치하는지
- API 요청 / 응답 형식이 Frontend와 일치하는지
- Database 변경이 다른 기능에 영향을 주지 않는지
- 관련 문서 수정이 필요한 경우 문서도 함께 변경되었는지

다른 담당자의 코드 또는 담당 영역을 수정한 경우 변경 내용을 해당 담당자에게 공유합니다.

---

## 7. Frontend / Backend 통합

Frontend와 Backend가 연결되는 기능은 각 저장소에서 따로 완료된 것으로 끝내지 않고,
실제 API 연동까지 확인합니다.

API 형식이 변경된 경우 Frontend와 Backend 담당자 모두에게 공유합니다.

---

## 8. Database 변경

Database 구조를 변경할 경우 Backend 담당자에게 변경 내용을 공유합니다.

테이블, 컬럼, 타입 또는 제약조건 변경이 Backend 코드에 영향을 주는지 함께 확인합니다.

DB 접속 정보, 비밀번호 등 민감한 값은 GitHub에 Commit하지 않습니다.

---

## 9. 문서 관리

기능 또는 구조를 변경하여 기존 문서와 실제 프로젝트 상태가 달라지는 경우
관련 문서도 함께 수정합니다.

- Frontend 관련 내용 → Frontend `README.md`
- Backend 관련 내용 → Backend `README.md`
- 공통 협업 규칙 → `CONTRIBUTING.md`
- 팀원 역할 / 담당 → `TEAM.md`
- 개발 환경 → 해당 저장소의 개발 환경 문서

같은 규칙을 여러 문서에 중복해서 정의하지 않습니다.

---

## 10. Merge 전 확인

Merge 전 다음 내용을 확인합니다.

- 작업 브랜치의 기능이 정상 동작하는가
- 대상 통합 브랜치와 충돌이 없는가
- 불필요한 파일이 포함되지 않았는가
- 관련 문서가 현재 상태와 일치하는가
- 다른 담당자의 확인이 필요한 변경을 공유했는가

검토가 끝나지 않은 작업은 `main`에 바로 Merge하지 않습니다.
