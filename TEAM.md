# CYCIRENTAL 팀 역할

CYCIRENTAL 프로젝트의 팀원별 주요 담당 영역을 정리합니다.

역할이나 담당 영역이 변경될 경우 이 문서를 기준으로 수정합니다.

---

## 백진욱

- 프로젝트 총괄
- 전체 디자인 방향 관리
- UI / UX 검토
- Database 관리
- Frontend / Backend 통합 진행 상황 확인
- Pull Request 및 프로젝트 구조 확인

---

## 문제혁

- Frontend 개발
- UI / UX 개발
- Frontend 총괄
- Frontend 코드 리뷰
- Frontend 기능 통합
- 서버 환경 구축
- 서버 관리 및 유지 보수
- Backend 자동 배포 환경 구축 및 관리

---

## 김현수

- Backend 개발
- API 개발
- Database 연동
- Backend 코드 리뷰

---

## 이재원

- Backend 개발
- API 개발
- Database 연동
- Backend 코드 리뷰

---

## 리뷰 및 공유 기준

### Frontend

- Frontend 코드 / 구조: Frontend 담당자 검토
- UI / UX 및 전체 디자인 방향: 백진욱 검토

### Backend

- Backend 기능: Backend 담당자 간 상호 검토
- API 변경: Frontend 연동에 영향이 있는 경우 Frontend 담당자에게 공유

### Database

- Database 구조 및 운영: 백진욱 관리
- 테이블 / 컬럼 / 제약조건 변경 시 Backend 담당자에게 공유
- Backend 코드 변경으로 Database 구조 변경이 필요한 경우 백진욱에게 공유

### Server / Deployment

- 서버 환경 구축 및 운영: 문제혁
- 서버 관리 및 유지 보수: 문제혁
- Backend 자동 배포 환경 구축 및 관리: 문제혁
- Backend 실행 환경 또는 배포 방식 변경 시 Backend 담당자에게 공유

### 통합

Frontend와 Backend가 연결되는 기능은
각 담당자가 함께 실제 API 연동을 확인합니다.

---

## 문서 관리 원칙

역할 변경은 여러 README에 중복 작성하지 않고 이 문서에서 관리합니다.

각 저장소 README에서는 필요한 경우 이 문서를 링크하여 참조합니다.
