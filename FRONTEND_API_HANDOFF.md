# Frontend API 연결 현황과 계약

2026-11-03 로컬 코드 기준입니다. 인증 API는 구현·연결 코드가 있고, 아래 공지 API는 제안 상태입니다. 원격 반영 여부는 DB·배포 결과로 따로 확인합니다.

## 인증 API — 로컬 구현

| 작업 | API | 요청 / 응답 |
| --- | --- | --- |
| 가입 | POST /api/auth/signup | displayName, studentNumber, phoneNumber, password → 201 |
| 로그인 | POST /api/auth/login | studentNumber, password → 사용자·토큰 → 200 |
| 로그아웃 | POST /api/auth/logout | Bearer 토큰 → 204 |
| 초기화 요청 | POST /api/auth/password-reset/requests | displayName, studentNumber → 202 |
| 관리자 대기 목록 | GET /api/admin/password-reset-requests | Bearer 토큰 → 오래된 순 최대 100건 |
| 관리자 초기화 | POST /api/admin/password-reset-requests/{id}/approve | Bearer + identityConfirmed:true → temporaryPassword, expiresAt |
| 관리자 거절 | POST /api/admin/password-reset-requests/{id}/reject | Bearer → 200 |
| 비밀번호 변경 | POST /api/auth/password/change | Bearer + currentPassword, newPassword → 새 사용자·토큰 → 200 |

회원가입은 이름 / 학번 / 비밀번호 / 비밀번호 확인 / 전화번호 순으로 입력합니다. 요청에는 확인용 비밀번호를 보내지 않습니다.
이름은 2~30자, 일반 학번은 숫자 6~12자리, 비밀번호는 8~64자입니다. 전화번호는 국내 휴대전화번호를 숫자 10~11자리로 받습니다. 학번과 전화번호는 앞자리 0을 보존하는 문자열입니다.
학번을 로그인 아이디로 사용하며 별도 아이디·이메일 입력과 아이디 찾기는 제거했습니다. 새 계정은 학생 권한으로만 생성됩니다.
예약 관리자 학번 `001`은 로그인·초기화 요청에서만 예외로 허용합니다. 일반 회원가입으로 만들 수 없고, DB의 관리자 계정과 서버 인증 성공 응답이 필요합니다. 앱에 고정 로그인 우회는 없습니다.

초기화는 이름·학번으로 요청한 뒤 관리자가 학생증 등으로 본인을 확인해 처리합니다. 이름·학번·전화번호 입력만으로 본인 인증을 완료한 것으로 보지 않습니다.
계정이 없거나 정보가 달라도 요청 응답은 같은 202이며, 동일 계정의 대기 요청은 중복 생성하지 않습니다.
관리자 승인 시 서버가 무작위 임시 비밀번호를 만들고 해시만 저장합니다. 임시 비밀번호는 24시간 유효하며 관리자 화면에 한 번 표시하므로 본인에게 별도로 전달합니다. 문자 발송·전화번호 인증은 연결하지 않았습니다.
초기화 시 기존 세션을 폐기합니다. `mustChangePassword=true`로 로그인하면 홈 진입 전 새 비밀번호 설정을 완료해야 합니다. 서버도 변경 전 관리자 API 사용을 거부합니다.
변경 완료 시 기존 세션을 폐기하고 새 토큰을 발급합니다. 일반 로그인 토큰은 7일 유효합니다. 기존 토큰 방식의 POST /api/auth/password-reset은 410, /api/auth/find-id는 제거 상태입니다.

로그인·비밀번호 변경 응답은 userId, loginId, displayName, accessToken, tokenType, isAdmin, studentNumber, mustChangePassword를 포함합니다.
앱은 userId를 로컬 대여 소유자 구분에 사용하고 isAdmin으로 관리자 메뉴를 결정합니다. 관리자 초기화 API는 서버에서 토큰·만료·DB 권한을 확인합니다.
전화번호는 가입 요청의 phoneNumber로 전달하며 현재 로그인 응답에는 포함하지 않습니다. 번호 인증·문자 발송·전화번호 수정 API는 미구현입니다.
`displayName`은 API 필드명이며 백엔드의 `User.displayName`을 통해 기존 DB `users.user_name`에 저장합니다. 이름 필드를 맞추려고 DB에 `displayName` 컬럼을 새로 만들거나 기존 컬럼을 삭제하지 않습니다.
400은 입력 오류, 401은 인증 실패·만료, 403은 권한 부족, 409는 중복·이미 처리된 요청입니다. 가능한 경우 서버의 detail을 표시합니다.

연결 지점: `mobile/lib/auth_api.dart`, `account_screens.dart`, `recovery_screens.dart`, `main.dart`.
DB 구조와 관리자 등록 절차는 백엔드의 [REMOTE_SCHEMA_ALIGNMENT.md](https://github.com/cycirental-team/cycirental-backend/blob/main/REMOTE_SCHEMA_ALIGNMENT.md)를 기준으로 합니다. 해당 문서는 이 변경을 Git에 반영한 후 원격에서 확인할 수 있습니다.

## 물품 조회 — 연결됨

앱은 GET /api/items로 목록·수량을 가져오며 검색·상세 화면에 사용합니다. 관리자 물품 등록·수정은 아직 메모리 방식입니다.
연결 지점은 `mobile/lib/item_api.dart`, `item_model.dart`, `item_store.dart`입니다.

## 공지사항

현재 구현: 관리자 공지 목록·작성·수정·삭제 확인·중요 공지 지정, 학생 홈 1개 노출·목록·상세 조회.
중요 공지를 우선하고 같은 중요도에서는 수정일이 최신인 공지를 먼저 표시합니다.
현재 데이터는 메모리에서만 저장되며 앱을 종료하면 초기화됩니다.

| 작업 | 제안 API | 권한 |
| --- | --- | --- |
| 목록 조회 | GET /api/notices | 로그인 사용자 |
| 상세 조회 | GET /api/notices/{id} | 로그인 사용자 |
| 등록 | POST /api/notices | 관리자 |
| 수정 | PATCH /api/notices/{id} | 관리자 |
| 삭제 | DELETE /api/notices/{id} | 관리자 |

공지 데이터: `id`, `title`, `body`, `isImportant`, `createdAt`, `updatedAt`.
작성 요청: `title`, `body`, `isImportant`. ID·작성일·수정일·작성자는 서버에서 결정해야 합니다.
화면 검증: 제목 1~80자, 내용 1~5000자. 서버 제한과 합의 후 맞춰야 합니다.
학생 요청의 등록·수정·삭제는 UI 숨김 외에 서버에서도 거부해야 합니다.

프론트 연결 지점: `mobile/lib/notice_store.dart`의 `save`, `delete`, `notices`와 `featured`.
새 API를 연결할 때 로딩·실패·재시도와 실패 시 기존 데이터 유지 처리가 필요합니다.


## 대여·반납 — 미연결

신청·승인·거절·취소·만료·반납 요청·반납 확인은 같은 앱 메모리에서만 처리합니다. 서버 저장·기기 간 공유·서버 권한과 재고 동시성 검증은 대여 API 연결 시 구현합니다.
서버 주소는 Git 제외된 `mobile/config/local-api.json`으로 지정하며 공용 기본값은 `http://10.0.2.2:8080`을 유지합니다.
