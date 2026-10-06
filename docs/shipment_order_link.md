# 배송과 주문 연결

`shipment.purchase_purchase_id`를 배송의 주문번호로 사용한다.
새 DB에 적용할 때는 `python -m db.migrate_shipment_order`를 실행한다.
기존 배송 기록의 주문번호는 자동 추측하거나 채우지 않는다.

배송 생성 API `POST /shipment/upload`와 기존 수정 API에
`purchase_purchase_id` 폼 필드를 전달한다. 저장 전에 주문번호와 배송 상품 ID가
정확히 하나의 구매 기록에 대응하는지 검증한다.
주문번호가 없거나 여러 구매 기록과 겹치는 연결은 422로 거절한다.
주문 연결을 생략한 기존 요청은 계속 사용할 수 있다.

수령 상품정보는 `receive_payment_id`와 `user_user_id`로 구매 목록을 조회해 표시한다.
한 결제에 여러 상품이 있으면 상품명을 함께 표시한다. 상품별 수령 완료까지
구분하려면 별도 상품 단위 수령 연결이 필요하다.

반품 환불 상태는 `return_record.refund_refund_id`가 연결된 환불 기록을
유일하게 찾을 때 `환불완료`로 표시한다.
새 DB에는 `python -m db.migrate_return_refund`로 연결 필드를 추가한다.
반품 생성 및 수정 API에 `refund_refund_id` 폼 필드를 전달하면 연결할 수 있다.
환불번호가 존재하지 않거나 여러 환불 기록과 겹치면 422로 거절한다.
기존 반품 기록의 환불번호는 임의로 채우지 않는다.
