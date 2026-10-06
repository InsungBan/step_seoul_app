# STEP SEOUL HQ

첨부 UI 기준의 Flutter 본사 콘솔입니다. 실제 MySQL 데이터를 `/hq/snapshot`으로 조회하며 없는 값은 해당 셀·카드·패널에 `데이터가 없습니다.`를 표시합니다.

## 실행

각 사용자 PC에서 API 서버를 실행합니다. 고정 IP의 MySQL에 해당 PC가 접근할 수 있어야 합니다.

```powershell
python main.py
```

또는:

```powershell
python -m uvicorn main:app --host 0.0.0.0 --port 8000
```

Android 에뮬레이터에서:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

로컬 Chrome에서:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

기본 주소도 Android는 `10.0.2.2:8000`, 웹·데스크톱은 `127.0.0.1:8000`입니다. 실제 기기는 PC의 LAN 주소를 지정하세요. Android Studio 실행 구성의 `--dart-define`은 기본값보다 우선됩니다.

## 화면

- 대시보드, 최종결재함, 주문·배송·수령·반품·회수·환불, 주문 상세
- 상품/대리점 재고 및 변동 이력, 상품 재고 상세
- 품의 목록과 작성, 발주·수주·입고·제조와 발주 상세
- 일별 매출 차트, 판매 TOP 5, 카테고리·대리점별 판매 패널
- 사용자·직원·대리점·신발·제조사 기준 정보와 지역별 대리점 차트

폭 1000 이상에서 사이드바를 고정 표시하고 작은 화면에서는 메뉴를 사용합니다. 표는 가로 스크롤과 페이지 이동을 제공합니다.
기간·상태·검색 조건은 실제 데이터에 적용하며 날짜가 없는 데이터는 기간 검색 결과에서 제외합니다.

## 데이터 및 쓰기 범위

매출은 결제 상태 코드 1을 완료로 사용합니다. 재고 비율은 현재재고/기준재고, 부족은 30% 미만입니다. 판매 순위는 결제 완료된 구매만 집계합니다.
관계가 불명확한 주문·배송·반품 또는 발주·수주는 임의로 연결하지 않습니다.
품의 작성은 기존 CRUD로 제목·사유를 실제 DB에 저장합니다. 결재 요청·자동 발주·배송/수령 처리 등의 업무 실행은 필요한 관계·권한 데이터가 없어 제공하지 않습니다.

필요한 필드와 추가 API 후보는 [데이터 요구사항](docs/hq_data_requirements.md)에 정리했습니다. DB 테이블·필드는 변경하지 않았습니다.

## 검증

```powershell
python -m unittest discover -s tests
flutter test
flutter analyze
```
