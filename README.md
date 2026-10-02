# step_seoul_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## 직원 업무 데이터 API 연결

직원 화면은 /employee-operations/state 엔드포인트를 통해 업무 상태를 MySQL에 저장하고 앱 시작 시 복원합니다. 첫 실행 때 서버에 저장값이 없으면 현재 Mock 데이터를 한 번 저장하고, 이후 업무 변경은 600ms 단위로 묶어 저장합니다. 저장 테이블은 첫 API 요청 때 자동 생성됩니다.

FastAPI와 MySQL을 실행한 뒤 Flutter를 실행하세요. API 주소가 기본값과 다르면 실행 시 주소를 지정합니다.

```bash
python -m pip install -r requirements.txt
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
flutter run --dart-define=API_BASE_URL=http://<개발 PC의 LAN IP>:8000
```

Android 기기와 개발 PC가 API 서버에 접근할 수 있어야 합니다. 웹에서는 FastAPI CORS가 허용됩니다. 로그인과 직원 상태 저장은 같은 API_BASE_URL을 사용합니다.
