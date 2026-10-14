# DeptRental 모바일 앱

Flutter로 만든 학과 대여 물품 관리 앱입니다. 컨셉아트에 맞춘 로그인, 홈,
물품 목록·검색, 상세·대여 신청, 내 대여 현황·반납 처리, 알림 화면을 제공합니다.

물품 목록과 전체·대여 가능 수량은 Backend의 `GET /api/items`에서 가져옵니다.
기본 주소는 에뮬레이터용 `http://10.0.2.2:8080`입니다. 팀 서버 주소는 Git에서 제외한 로컬 설정 파일로 전달합니다.

다른 Backend 주소를 사용할 때는 다음처럼 실행합니다.

```powershell
flutter run --dart-define=API_BASE_URL=http://서버주소:포트
```

현재 실제 DB와 연결된 범위는 물품 조회입니다. 대여 신청과 반납 처리는 아직 Backend API가
구현되지 않아 앱을 종료하면 초기화되는 임시 상태로 동작합니다.

설치와 자세한 실행 방법은 저장소 루트의 [DEVELOPMENT.md](../DEVELOPMENT.md)를 참고하세요.
