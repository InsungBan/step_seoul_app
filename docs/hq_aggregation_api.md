# 본사 집계 API — 최신 요청 반영

`routers/hq.py`와 `services/hq_service.py`에 구현되어 있습니다.
응답은 `{result: [...], available: true|false, requires: [...]}`입니다. 스키마가 없으면 `available=false`, 데이터가 없으면 빈 목록 또는 정의 가능한 0을 반환합니다.

## 연결 기준

- 선택 대리점: `purchase.store_store_id → store.store_id`. 수령 기록에서 대리점을 대체 추정하지 않습니다.
- 품의 작성일: 해당 품의의 최신 결재 기록 `approval_process.approval_date`.
- 품의 신청 금액: `purchase_order.approval_approval_id`로 연결된 발주들의 `get_amount` 합계. 발주가 없으면 금액은 빈 상태입니다.
- 월간 입고량: 사용자 지정 기준으로 현재 월의 **수주일자 `get_order_date`**에 해당하는 **수주수량 `get_order_quantity`** 합계. 실제 입고일과 상태는 사용하지 않습니다.
- 반품률: 선택 기간의 반품 행 수 ÷ 같은 기간 결제 완료 구매 행 수 × 100. **건수 기준 기간 지표**이며 특정 구매 상품의 반품 비율과는 다른 정의입니다. 구매가 0건이면 비율은 NULL입니다.
- 대리점별 매출: 결제 완료된 구매를 구매 대리점→상품 카테고리 순으로 그룹화하고 `sale_price × quantity`를 합산합니다. 응답은 대리점 총액 내림차순이며 각 대리점에 `categories`로 카테고리별 금액·수량을 포함합니다.

## 사용 가능한 조회 API

| GET API | 내용 |
| --- | --- |
| `/hq/final-approvals/select` | 팀장 승인 후 이사 대기 중인 최신 결재 |
| `/hq/completed-receipts/select` | 수령 완료 목록 |
| `/hq/auto-order-targets/select` | 기준재고 30% 이하 상품 |
| `/hq/monthly-inbound/select` | 수주일자로 집계한 이번 달 수주수량 |
| `/hq/inventory-by-category/select` | 카테고리별 재고 |
| `/hq/auto-order-history/select` | `is_auto=1`인 발주 이력 |
| `/hq/return-rate/select` | 기간별 건수 기준 반품률 |
| `/hq/sales-by-category/select` | 카테고리별 매출 |
| `/hq/sales-by-store/select` | 대리점 총액 및 카테고리별 매출 |

매출과 반품률은 `start=YYYY-MM-DD&end=YYYY-MM-DD`로 기간을 지정합니다. 기본은 이번 달 1일~오늘입니다.
`/hq/snapshot`도 같은 인자를 받으며 `hq_reports`에 집계를 포함해 앱의 추가 네트워크 요청을 줄입니다.
사용하지 않는 재고 원장 API는 유지하지만 UI에는 노출하지 않습니다. 지연 조회 API는 제거했습니다.

## 현재 DB에 없는 필드

실제 DB를 확인했으며 아래 필드는 아직 없습니다. 데이터가 필요한 영역은 `데이터가 없습니다.`를 표시합니다.

- `purchase.store_store_id`: 선택 대리점과 대리점별 매출의 근거. 이 외래키가 추가되고 실제 값이 저장되면 API가 자동 감지합니다.
- `purchase_order.is_auto`: 자동 발주 이력 표시. 단순히 품의와 연결되어 있다는 이유로 자동 생성이라고 가정하지 않습니다.

DB 스키마나 기존 행은 수정하지 않았습니다.

## 삭제

- 주문·배송: 배송·수령·반품·회수·환불 프로세스 패널
- 재고: 최근 입고일 컬럼, 최근 재고 변동 패널, 재고 변동 탭, 상세 대리점별 재고 및 재고 변동
- 품의: 발주 상태 컬럼
- 발주·수주: 지연 지표, 발주 상태·수주 상태·입고예정일 컬럼, 입고 탭, 상세 지연·검수·담당자·납품일정·진행 상태
- 기준정보: 자치구별 대리점 차트

HQ 조회 응답에서 `get_order_status`와 입고예정일 관련 선택 필드를 제거했습니다.

## 적용

API 서버를 재시작하고 앱을 다시 실행하거나 새로고침합니다.
