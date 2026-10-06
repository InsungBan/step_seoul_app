"""Diverse, linked HQ samples. Dry-run by default; --apply commits inserts only.

python -m db.seed_varied --as-of 2026-10-02 --apply
Stable v26 IDs make reruns skip existing samples without updating any row.
"""
import argparse
from datetime import date, datetime, time, timedelta, timezone

from db.seed_dummy import build_rows as old_rows, seed


def build_rows(as_of):
    rows = {table: [] for table in old_rows()}
    def ident(kind, i):
        return f'v26{kind}{i:03d}'
    def stamp(value):
        return value.strftime('%Y-%m-%d %H:%M:%S')
    anchor = datetime.combine(as_of, time(17, 40))
    names = ['김민준', '이서연', '박지훈', '최수빈', '정하늘', '윤서준', '한지우', '송도윤']
    for i in range(40):
        rows['user'].append(dict(user_id=ident('u', i), user_name=f'샘플 {names[i % 8]} {i + 1}',
            user_phone=f'01077{i:06d}', user_pw='Sample26!', user_email=f'sample{i + 1}@example.com',
            join_date=stamp(anchor - timedelta(days=180 - i * 3, hours=i % 6))))
    departments = ['구매팀', '영업팀', '물류팀']
    for i in range(9):
        rows['employee'].append(dict(employee_id=ident('e', i), employee_pw='Sample26!',
            employee_name=f'샘플 {names[i % 8]}', employee_department=departments[i % 3],
            employee_position=['사원', '대리', '팀장', '이사'][i % 4]))
    for i, name in enumerate(['한빛슈즈', '서울풋웨어', '모던스텝', '그린워크', '에이스스포츠', '오로라제화']):
        rows['shoe_manufacturer'].append(dict(manufacturer_id=ident('m', i), manufacturer_name=f'샘플 {name}'))
    districts = ['강남구', '서초구', '마포구', '송파구', '중구', '성동구', '노원구', '영등포구']
    coords = [(37.4979,127.0276),(37.4837,127.0324),(37.5563,126.9236),(37.5133,127.1001),
              (37.5665,126.9780),(37.5633,127.0368),(37.6542,127.0568),(37.5264,126.8962)]
    for i, district in enumerate(districts):
        rows['store'].append(dict(store_id=ident('st', i), agency_name=f'샘플 {district} 수령점',
            district_name=district, phone=f'0277{i:06d}', latitude=coords[i][0], longitude=coords[i][1]))
    prices = [49000, 69000, 79000, 89000, 99000, 119000, 139000, 159000]
    standards = [30, 50, 80, 100, 120, 150, 200, 60]
    factors = [0, .08, .24, .3, .45, .69, .7, .95, 1, 1.4]
    shoes = ['라이트 러너', '데일리 워킹', '시티 스니커즈', '클래식 로퍼', '트레킹 부츠', '컴포트 샌들', '주니어 워커', '코트 스니커즈']
    for i in range(32):
        standard = standards[i % 8]
        rows['shoe'].append(dict(shoe_id=ident('s', i), brand_name=f'샘플 {shoes[i % 8]} {i // 8 + 1}',
            shoe_category=['러닝화', '워킹화', '스니커즈', '로퍼', '부츠', '샌들', '키즈', '스니커즈'][i % 8], shoe_image_url=None, shoe_price=str(prices[i % 8]), standard_stock=standard, stock_quantity=int(standard * factors[i % 10])))
        rows['manufacturing'].append(dict(shoe_shoe_id=ident('s', i), shoe_manufacturer_manufacturer_id=ident('m', i % 6),
            manufacturing_id=ident('mf', i), manufacturing_date=stamp(anchor - timedelta(days=100 - i, hours=i % 4))))
    # Only approved proposals create purchase orders. Schema has no order->get_order FK.
    for i in range(24):
        shoe = i % 32
        requested = [15, 30, 50, 80, 120, 200][i % 6]
        created = anchor - timedelta(days=32 - i, hours=i % 7, minutes=i * 2)
        status = ['결재대기', '승인', '승인', '반려', '결재대기', '승인'][i % 6]
        team = '대기' if i % 6 == 0 else '반려' if status == '반려' else '승인'
        director = '승인' if status == '승인' else '대기'
        rows['approval'].append(dict(approval_id=ident('a', i), approval_name=f'샘플 {shoes[shoe % 8]} 재고 확보 {i + 1}',
            approval_content=f'샘플 데이터: 상품 {ident("s", shoe)} 기준재고 확인 후 {requested}켤레 추가 발주 검토 요청.'))
        rows['approval_process'].append(dict(employee_employee_id=ident('e', i % 9), approval_approval_id=ident('a', i),
            approval_process_id=ident('ap', i), approval_date=stamp(created), director_approval=director,
            team_leader_approval=team, approval_status=status, processed_at=stamp(created + timedelta(hours=2)) if status != '결재대기' else None))
        if status != '승인':
            continue
        ordered = created + timedelta(days=1)
        rows['purchase_order'].append(dict(shoe_manufacturer_manufacturer_id=ident('m', shoe % 6), approval_approval_id=ident('a', i),
            order_id=ident('po', i), order_date=stamp(ordered), order_quantity=str(requested),
            shoe_shoe_id=ident('s', shoe), get_amount=str(prices[shoe % 8] * requested)))
        rows['get_order'].append(dict(shoe_shoe_id=ident('s', shoe), employee_employee_id=ident('e', i % 9),
            shoe_manufacturer_manufacturer_id=ident('m', shoe % 6), get_order_id=ident('go', i),
            get_order_quantity=str(requested), get_order_date=stamp(ordered + timedelta(hours=4)),
            get_order_status=['접수', '처리중', '완료', '입고대기', '입고완료'][i % 5]))
    returned = 0
    for i in range(96):
        age = i % 60
        when = datetime.combine(as_of - timedelta(days=age), time(8 + i % 9, (i * 13) % 60, (i * 7) % 60))
        shoe = (i * 7 + i // 32) % 32
        user, employee, store = ident('u', i % 40), ident('e', i % 9), ident('st', i % 8)
        quantity = [1, 2, 1, 3, 4, 2][i % 6]
        discounted = i % 4 == 0
        price = prices[shoe % 8] * (9 if discounted else 10) // 10
        paid = i % 7 != 0
        rows['payment'].append(dict(user_user_id=user, employee_employee_id=employee, payment_id=ident('pay', i),
            payment_date=stamp(when + timedelta(minutes=3)), payment_amount=price * quantity,
            payment_status=1 if paid else 0, discount_flag='Y' if discounted else 'N'))
        rows['purchase'].append(dict(shoe_shoe_id=ident('s', shoe), user_user_id=user, purchase_id=ident('buy', i), store_store_id=store,
            sale_price=str(price), payment_id=ident('pay', i), quantity=str(quantity)))
        rows['cart'].append(dict(user_user_id=user, shoe_shoe_id=ident('s', shoe), cart_id=ident('cart', i),
            added_at=stamp(when - timedelta(hours=1, minutes=i % 30))))
        if not paid:
            continue
        stage = 0 if age == 0 else 1 if age == 1 else 2 if age == 2 else 3 if i % 5 < 3 else 2 if i % 5 == 3 else 1
        rows['shipment'].append(dict(shoe_shoe_id=ident('s', shoe), employee_employee_id=employee, shipment_id=ident('sh', i),
            delivery_status=['발송준비', '배송중', '대리점도착', '배송완료'][stage], delivery_quantity=quantity, store_store_id=store))
        if stage < 2:
            continue
        completed = stage == 3
        received = when + timedelta(days=3, hours=1)
        rows['receive'].append(dict(store_store_id=store, user_user_id=user, employee_employee_id=employee, receive_id=ident('rv', i),
            receive_date=stamp(received) if completed else None, receive_quantity=str(quantity),
            receive_verification_code=str(700000 + i), receive_status='수령완료' if completed else '수령대기',
            receive_verification_status=1 if completed else 0, receive_expdate=stamp(when + timedelta(days=7)),
            receive_payment_id=ident('pay', i)))
        if completed:
            rows['authentication'].append(dict(user_user_id=user, employee_employee_id=employee,
                authentication_id=ident('auth', i), authentication_date=stamp(received - timedelta(minutes=5))))
        if not completed or age < 8 or returned >= 16:
            continue
        return_date = received + timedelta(days=2)
        rows['return_record'].append(dict(shoe_shoe_id=ident('s', shoe), employee_employee_id=employee,
            return_id=ident('rt', i), return_date=stamp(return_date)))
        if returned % 4 != 0:
            rows['recall'].append(dict(store_store_id=store, user_user_id=user, employee_employee_id=employee,
                recall_id=ident('rc', i), recall_date=stamp(return_date + timedelta(days=1)), recall_quantity=1))
            if returned % 3 != 0:
                rows['refund'].append(dict(user_user_id=user, employee_employee_id=employee, refund_id=ident('rf', i),
                    refund_amount=str(price), refund_quantity='1', refund_reason=['샘플: 사이즈 변경','샘플: 상품 불량','샘플: 색상 변경','샘플: 단순 변심'][returned % 4],
                    refund_cardnumber=0))
        returned += 1
    return rows


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    parser.add_argument('--as-of', type=date.fromisoformat,
                        default=datetime.now(timezone(timedelta(hours=9))).date())
    args = parser.parse_args()
    seed(apply=args.apply, rows=build_rows(args.as_of))

