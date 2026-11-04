# Git 업로드 전 준비 — Frontend

백엔드·프론트 저장소는 각각 정리합니다. 이 절차의 끝은 로컬 검증·문서 준비이며, push·PR·main 병합과 서버 배포는 사용자가 직접 진행합니다.

## 1. DB와 백엔드 준비 확인

DB 백업·구조 확인·인증 스키마 변경·001 관리자 등록은 백엔드의 [원격 DB 준비 문서](https://github.com/cycirental-team/cycirental-backend/blob/main/REMOTE_SCHEMA_ALIGNMENT.md)를 기준으로 합니다.
DB 준비 없이 새 백엔드만 배포하면 로그인·가입이 실패할 수 있습니다. 백엔드와 프론트 변경을 각각 구분해 준비합니다.

## 2. 로컬 설정과 검증

Android Studio 실행 설정은 [DEVELOPMENT.md](DEVELOPMENT.md#android-studio-실폰-테스트)를 따릅니다.

```powershell
cd C:\fq_mob\cycirental\mobile
flutter analyze
flutter test --concurrency=1
```

실폰 가입·로그인·관리자·초기화 검증은 원격 DB와 백엔드 반영 후 진행합니다. 대여·반납의 기기 간 공유는 아직 검증 대상이 아니라 미연결 기능입니다.

## 3. Git 포함 파일 확인

```powershell
cd C:\fq_mob\cycirental
git status --short
git diff --check
git diff --stat
git check-ignore mobile/config/local-api.json
```

실제 서버 IP·DB 비밀번호·로컬 설정·백업·빌드 파일이 포함되지 않게 확인합니다. 새 파일과 `demo_auth.dart` 삭제 / `app_user.dart` 추가도 누락하지 않습니다.
생성된 Windows 플러그인 파일이 변경 목록에 있다면 실제 내용 차이를 확인하고 기능 변경에 필요하지 않은 생성 결과는 함께 올리지 않습니다.

## 4. 저장소별 정리

프론트는 `front/* → front-dev → main`, 백엔드는 `back/* → back-dev → main`입니다. [CONTRIBUTING.md](CONTRIBUTING.md)를 유지합니다.
이미 main에 로컬 변경이 있는 상태에서는 pull·reset·브랜치 전환으로 변경을 잃지 않도록 먼저 상태를 확인합니다. 기능 변경·문서 변경을 검토하고 각각 목적에 맞게 커밋을 준비합니다.
현재 단계에서는 업로드나 main 병합을 자동 실행하지 않습니다.
