# STEP SEOUL

STEP SEOUL은 서울 지역 매장·고객·직원·본사 운영을 지원하는 통합 쇼핑/주문/재고 관리 서비스입니다. 이 프로젝트는 Flutter 기반 모바일 앱과 FastAPI 기반 백엔드 API를 함께 포함하고 있으며, 고객용 쇼핑 플로우, 직원용 업무 화면, 본사 통합 콘솔을 모두 운영합니다.

## 프로젝트 개요

- 프론트엔드: Flutter + Dart
- 백엔드: FastAPI + Python
- 데이터베이스: SQLite / 기존 DB 연결 구조를 활용
- 인증: 사용자/직원/임원 역할 기반 세션 관리
- 기능 영역: 회원가입/로그인, 고객 쇼핑, 장바구니, 결제, 주문 내역, 반품, 직원 업무, 본사 대시보드

이 저장소는 단일 앱이 아니라 다음 두 계층을 함께 포함합니다.

1. 고객/직원/임원용 Flutter 앱
2. REST API 서버를 제공하는 Python FastAPI 서비스

---

## 주요 기능

### 1. 고객 기능
- 회원가입 및 로그인
- 매장 검색 및 지점 상세 조회
- 신발 상품 목록/상세 보기
- 장바구니 추가, 수정, 삭제
- 결제 및 주문 완료
- 주문 상세 및 반품 요청
- 마이페이지 및 프로필 수정

### 2. 직원 기능
- 작업 홈 화면
- 주문/배송/수령/재고 관련 업무 처리
- 직원별 작업 흐름 및 세션 기반 접근

### 3. 본사(HQ) 기능
- 실시간 대시보드
- 주문/재고/매출/지점 통계
- 결재 문서 관리
- 제조, 발주, 입고, 반품, 환불 등 운영 데이터 조회
- 팀/권한 기반 업무 화면 구성

---

## 기술 스택

### Frontend
- Flutter
- Dart
- GetX
- Firebase Core / Firestore / Messaging / Storage
- geolocator, geocoding
- flutter_map

### Backend
- FastAPI
- Uvicorn
- Python
- PyMySQL
- python-multipart

---

## 저장소 구조

```text
step_seoul_app/
├── lib/                     # Flutter 앱 소스
│   ├── hq/                 # 본사 화면
│   ├── model/              # 데이터 모델
│   ├── routes/             # 앱 라우팅 및 경로 정의
│   ├── services/           # API 통신 및 세션 처리
│   ├── view/               # 화면 UI
│   ├── vm/                 # ViewModel 계층
│   ├── widgets/            # 공통 위젯
│   ├── main.dart           # Flutter 앱 진입점
│   └── firebase_options.dart
├── routers/                # FastAPI 라우터
├── services/               # 백엔드 비즈니스 로직
├── db/                     # DB 관련 스크립트 및 seed data
├── docs/                   # 프로젝트 문서
├── scripts/                # 유틸리티 스크립트
├── tests/                  # Python 테스트
├── test/                   # Flutter 테스트
├── main.py                 # FastAPI 서버 진입점
├── requirements.txt        # Python 의존성
├── pubspec.yaml            # Flutter 의존성
├── analysis_options.yaml   # Dart 분석 설정
├── firebase.json          # Firebase 설정
├── android/               # Android 프로젝트
├── ios/                   # iOS 프로젝트
├── web/                   # Web 프로젝트
├── README.md              # 프로젝트 설명서
└── .gitignore
```

---

## 실행 방법

### 1) Python 백엔드 실행

프로젝트 루트에서 아래 중 하나를 실행합니다.

```powershell
python main.py
```

또는:

```powershell
python -m uvicorn main:app --host 0.0.0.0 --port 8000
```

기본적으로 API는 다음 포트에서 실행됩니다.

- 기본: `http://localhost:8000`
- 또는 `0.0.0.0:8000`

> Android 에뮬레이터에서는 `localhost` 대신 `10.0.2.2`를 사용해야 합니다.

---

### 2) Flutter 앱 실행

#### Android 에뮬레이터

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

#### 로컬 웹/Chrome

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

#### 실제 기기

```powershell
flutter run --dart-define=API_BASE_URL=http://<PC_LOCAL_IP>:8000
```

예시:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.0.12:8000
```

> 실제 기기에서 실행할 때는 PC의 LAN IP를 사용해야 하며, 에뮬레이터에서는 `10.0.2.2`를 사용해야 합니다.

---

### 3) 의존성 설치

#### Python

```powershell
python -m pip install -r requirements.txt
```

#### Flutter

```powershell
flutter pub get
```

---

## 앱 흐름

### 로그인/권한 흐름

- 사용자 유형은 다음과 같이 구분됩니다.
  - Customer
  - Employee
  - Executive
- 앱 실행 시 `AuthGate`에서 저장된 세션을 확인합니다.
- 세션이 있으면 해당 역할에 맞는 화면으로 이동합니다.
- 세션이 없으면 로그인 화면으로 이동합니다.

### 역할별 화면

- Customer: 고객 메인 홈, 상품 조회, 장바구니, 결제, 마이페이지
- Employee: 직원 업무 홈
- Executive: 본사 대시보드(HQ Console)

---

## 주요 문서

다음 문서들을 읽으면 기능과 데이터 모델을 더 쉽게 이해할 수 있습니다.

- [docs/crud.md](docs/crud.md)
- [docs/hq_data_requirements.md](docs/hq_data_requirements.md)
- [docs/approval_submission_api.md](docs/approval_submission_api.md)
- [docs/hq_aggregation_api.md](docs/hq_aggregation_api.md)

이 문서들은 API 요구사항, CRUD 동작, 대시보드 집계 로직 등을 정리해 둔 자료입니다.

---

## DB 및 seed 관련 작업

`db/` 폴더에는 초기 데이터 생성 및 마이그레이션 관련 스크립트가 포함되어 있습니다.

```powershell
python db/seed_empty.py
python db/seed_dummy.py
```

필요에 따라 다음과 같은 스크립트도 실행할 수 있습니다.

- `db/migrate_approval_amount.py`
- `scripts/seed_seoul_stores.py`
- `scripts/sync_shoe_images.py`
- `scripts/upload_shoe_images.py`

---

## 테스트

### Python 테스트

```powershell
python -m unittest discover -s tests
```

### Flutter 테스트

```powershell
flutter test
```

### 정적 분석

```powershell
flutter analyze
```

---

## 주의사항

- Android 에뮬레이터는 API 주소를 `10.0.2.2`로 설정해야 합니다.
- 실제 기기는 `localhost` 대신 PC의 LAN IP를 사용해야 합니다.
- FastAPI 서버와 Flutter 앱이 같은 네트워크/환경에서 통신할 수 있어야 합니다.
- 권한별 화면 접근은 세션(Role) 기반으로 동작하므로, 로그인 상태와 역할 저장을 확인하는 것이 중요합니다.

---

## 개발 팁

- 로컬 개발 시 백엔드 서버를 먼저 실행한 뒤 앱을 구동하는 것을 권장합니다.
- API 변경이 있을 때는 `routers/`와 `services/`를 함께 확인해 구현을 맞춰야 합니다.
- UI 라우팅은 `lib/routes`와 `GetPage` 설정을 기준으로 확인하면 편합니다.
- 본사 콘솔은 `lib/hq/` 아래 화면 위주로 구성되어 있으므로 해당 폴더를 우선 확인하면 됩니다.

---

## 라이선스

이 프로젝트는 내부 운영/개발용 서비스로 구성되어 있으며, 공개 배포 전 라이선스 및 보안 정책을 재검토하는 것을 권장합니다.

