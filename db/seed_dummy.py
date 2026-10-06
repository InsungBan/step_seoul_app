"""Add five related demo rows per table without changing existing data.

Run from the repository root: python -m db.seed_dummy --apply
Without --apply, inserts are validated and rolled back.
"""

import argparse
import json
from pathlib import Path

from db.database import db


def build_rows():
    rows = {name: [] for name in (
        'user', 'employee', 'shoe_manufacturer', 'shoe', 'store', 'approval',
        'approval_process', 'authentication', 'cart', 'get_order',
        'manufacturing', 'payment', 'purchase', 'purchase_order', 'recall',
        'receive', 'refund', 'return_record', 'shipment',
    )}
    for i in range(1, 6):
        def ident(kind):
            return f'demo_{kind}{i:02d}'

        user, employee, shoe = ident('u'), ident('e'), ident('s')
        manufacturer, store, approval = ident('m'), ident('st'), ident('a')
        payment = ident('pay')
        date = f'2026-10-0{i} 10:00:00'
        price = [89000, 119000, 99000, 79000, 139000][i - 1]
        rows['user'].append(dict(
            user_id=user, user_name=f'테스트고객{i}', user_phone=f'0100000000{i}',
            user_pw='Demo1234!', user_email=f'demo{i}@example.com', join_date='2026-09-01 09:00:00'))
        rows['employee'].append(dict(
            employee_id=employee, employee_pw='Demo1234!',
            employee_position=['사원', '사원', '대리', '팀장', '부장'][i - 1],
            employee_name=f'테스트직원{i}', employee_department='영업팀'))
        rows['shoe_manufacturer'].append(dict(
            manufacturer_id=manufacturer, manufacturer_name=f'테스트제조사{i}'))
        rows['shoe'].append(dict(
            shoe_id=shoe, brand_name=['테스트 러닝', '테스트 워킹', '테스트 스니커즈', '테스트 캐주얼', '테스트 트레킹'][i - 1],
            shoe_price=str(price), standard_stock=20, stock_quantity=[50, 10, 30, 5, 80][i - 1]))
        rows['store'].append(dict(
            store_id=store, latitude=[37.5665, 37.4979, 37.5563, 37.5133, 37.5800][i - 1],
            longitude=[126.9780, 127.0276, 126.9236, 127.1001, 127.0460][i - 1],
            district_name=['중구', '강남구', '마포구', '송파구', '동대문구'][i - 1],
            agency_name=f'테스트매장{i}', phone=f'020000000{i}'))
        rows['approval'].append(dict(
            approval_id=approval, approval_name=f'테스트 상품 발주 {i}',
            approval_content=f'더미데이터: 상품 {shoe} 10켤레 발주 승인 요청'))
        rows['approval_process'].append(dict(
            employee_employee_id=employee, approval_approval_id=approval,
            approval_process_id=ident('ap'), approval_date=date,
            director_approval='승인', team_leader_approval='승인',
            approval_status='승인', processed_at=date))
        rows['authentication'].append(dict(
            user_user_id=user, employee_employee_id=employee,
            authentication_id=ident('auth'), authentication_date=date))
        rows['cart'].append(dict(
            user_user_id=user, shoe_shoe_id=shoe, cart_id=ident('cart'), added_at=date))
        rows['get_order'].append(dict(
            shoe_shoe_id=shoe, employee_employee_id=employee,
            get_order_id=ident('go'), get_order_quantity='10', get_order_status='입고완료',
            get_order_date=date, shoe_manufacturer_manufacturer_id=manufacturer))
        rows['manufacturing'].append(dict(
            shoe_shoe_id=shoe, shoe_manufacturer_manufacturer_id=manufacturer,
            manufacturing_id=ident('mf'), manufacturing_date='2026-09-20 10:00:00'))
        rows['payment'].append(dict(
            user_user_id=user, employee_employee_id=employee, payment_id=payment,
            payment_date=date, payment_amount=price * 2, payment_status=1, discount_flag='N'))
        rows['purchase'].append(dict(
            shoe_shoe_id=shoe, user_user_id=user, purchase_id=ident('buy'),
            sale_price=str(price), payment_id=payment, quantity='2'))
        rows['purchase_order'].append(dict(
            shoe_manufacturer_manufacturer_id=manufacturer, approval_approval_id=approval,
            order_date='2026-09-25 10:00:00', get_amount=str(price * 10),
            order_id=ident('po'), order_quantity='10', shoe_shoe_id=shoe))
        rows['recall'].append(dict(
            store_store_id=store, user_user_id=user, recall_id=ident('rc'),
            recall_date=f'2026-10-{i + 10:02d} 10:00:00', recall_quantity=1,
            employee_employee_id=employee))
        rows['receive'].append(dict(
            store_store_id=store, user_user_id=user, employee_employee_id=employee,
            receive_id=ident('rv'), receive_date=f'2026-10-{i + 5:02d} 10:00:00',
            receive_quantity='2', receive_verification_code=f'10000{i}',
            receive_status='수령완료', receive_verification_status=1,
            receive_expdate='2026-10-31 23:59:59', receive_payment_id=payment))
        rows['refund'].append(dict(
            user_user_id=user, employee_employee_id=employee, refund_id=ident('rf'),
            refund_amount=str(price), refund_quantity='1',
            refund_reason='테스트: 사이즈 변경', refund_cardnumber=1000 + i))
        rows['return_record'].append(dict(
            shoe_shoe_id=shoe, employee_employee_id=employee,
            return_id=ident('rt'), return_date=f'2026-10-{i + 10:02d} 10:00:00'))
        rows['shipment'].append(dict(
            shoe_shoe_id=shoe, employee_employee_id=employee, shipment_id=ident('sh'),
            delivery_status='배송완료', delivery_quantity=2, store_store_id=store))
    return rows


def seed(apply=False, rows=None):
    schema = json.loads(Path(__file__).with_name('schema.json').read_text(encoding='utf-8'))
    rows = build_rows() if rows is None else rows
    connection = db()
    try:
        with connection.cursor() as cursor:
            cursor.execute('SHOW TABLE STATUS')
            engines = {row[0]: row[1] for row in cursor.fetchall()}
            if any(engines.get(table) != 'InnoDB' for table in rows):
                raise RuntimeError('All seeded tables must use InnoDB for safe rollback.')
            connection.begin()
            report = {}
            for table, records in rows.items():
                cursor.execute(f'SHOW COLUMNS FROM `{table}`')
                definitions = cursor.fetchall()
                actual = {row[0] for row in definitions}
                expected = {column['COLUMN_NAME'] for column in schema['columns']
                            if column['TABLE_NAME'] == table}
                if not expected.issubset(actual):
                    raise RuntimeError(f'Required columns changed for {table}; review before seeding.')
                for definition in definitions:
                    if definition[0] not in expected and definition[2] == 'NO' and definition[4] is None and 'auto_increment' not in definition[5]:
                        raise RuntimeError(f'New required column in {table}: {definition[0]}')
                if any(not set(record).issubset(actual) for record in records):
                    raise RuntimeError(f'Unknown sample columns for {table}')
                keys = [column['COLUMN_NAME'] for column in schema['columns']
                        if column['TABLE_NAME'] == table and column['COLUMN_KEY'] == 'PRI']
                cursor.execute(f'SELECT COUNT(*) FROM `{table}`')
                before = cursor.fetchone()[0]
                inserted = skipped = 0
                for record in records:
                    where = ' AND '.join(f'`{key}` = %s' for key in keys)
                    cursor.execute(f'SELECT 1 FROM `{table}` WHERE {where}',
                                   tuple(record[key] for key in keys))
                    if cursor.fetchone():
                        skipped += 1
                        continue
                    columns = ', '.join(f'`{name}`' for name in record)
                    placeholders = ', '.join('%s' for _ in record)
                    cursor.execute(f'INSERT INTO `{table}` ({columns}) VALUES ({placeholders})',
                                   tuple(record.values()))
                    inserted += 1
                cursor.execute(f'SELECT COUNT(*) FROM `{table}`')
                after = cursor.fetchone()[0]
                if after != before + inserted:
                    raise RuntimeError(f'Unexpected row count for {table}')
                report[table] = dict(before=before, inserted=inserted, skipped=skipped, after=after)
            # Check every declared foreign key, limited to the requested sample rows.
            for fk in schema['foreign_keys']:
                for record in rows[fk['TABLE_NAME']]:
                    cursor.execute(
                        f"SELECT 1 FROM `{fk['REFERENCED_TABLE_NAME']}` "
                        f"WHERE `{fk['REFERENCED_COLUMN_NAME']}` = %s",
                        (record[fk['COLUMN_NAME']],))
                    if not cursor.fetchone():
                        raise RuntimeError(f'Missing demo reference: {fk}')
            if apply:
                connection.commit()
            else:
                connection.rollback()
            print(json.dumps(dict(committed=apply, tables=report), ensure_ascii=False, indent=2))
    except Exception:
        connection.rollback()
        raise
    finally:
        connection.close()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true', help='Commit the demo rows')
    seed(parser.parse_args().apply)
