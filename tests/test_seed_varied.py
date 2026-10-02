import json
import unittest
from datetime import date, datetime
from pathlib import Path
from db.seed_varied import build_rows


class VariedSampleTests(unittest.TestCase):
    def setUp(self):
        self.rows = build_rows(date(2026, 10, 2))

    def test_keys_fit_schema_and_all_references_exist(self):
        schema = json.loads(Path('db/schema.json').read_text(encoding='utf-8'))
        for table, records in self.rows.items():
            columns = [c for c in schema['columns'] if c['TABLE_NAME'] == table]
            keys = [c['COLUMN_NAME'] for c in columns if c['COLUMN_KEY'] == 'PRI']
            identities = [tuple(r[k] for k in keys) for r in records]
            self.assertEqual(len(identities), len(set(identities)), table)
            for record in records:
                for column in columns:
                    value = record.get(column['COLUMN_NAME'])
                    if column['IS_NULLABLE'] == 'NO':
                        self.assertIsNotNone(value)
                    if value is not None and column['COLUMN_TYPE'].startswith('varchar('):
                        limit = int(column['COLUMN_TYPE'][8:-1])
                        self.assertLessEqual(len(str(value)), limit)
        for fk in schema['foreign_keys']:
            ids = {r[fk['REFERENCED_COLUMN_NAME']] for r in self.rows[fk['REFERENCED_TABLE_NAME']]}
            for record in self.rows[fk['TABLE_NAME']]:
                self.assertIn(record[fk['COLUMN_NAME']], ids)

    def test_financial_totals_and_fulfilment_are_consistent(self):
        payments = {r['payment_id']: r for r in self.rows['payment']}
        purchases = {r['payment_id']: r for r in self.rows['purchase']}
        for payment in payments.values():
            purchase = purchases[payment['payment_id']]
            self.assertEqual(payment['payment_amount'], int(purchase['sale_price']) * int(purchase['quantity']))
        for receipt in self.rows['receive']:
            payment = payments[receipt['receive_payment_id']]
            self.assertEqual(payment['payment_status'], 1)
            self.assertEqual(payment['user_user_id'], receipt['user_user_id'])
            if receipt['receive_status'] == '수령완료':
                self.assertGreater(datetime.fromisoformat(receipt['receive_date']), datetime.fromisoformat(payment['payment_date']))
            else:
                self.assertIsNone(receipt['receive_date'])
        approvals = {r['approval_approval_id']: r for r in self.rows['approval_process']}
        for order in self.rows['purchase_order']:
            self.assertEqual(approvals[order['approval_approval_id']]['approval_status'], '승인')

    def test_diversity_for_charts_and_filters(self):
        dates = {r['payment_date'][:10] for r in self.rows['payment']}
        self.assertEqual(len(dates), 60)
        self.assertEqual({r['payment_status'] for r in self.rows['payment']}, {0, 1})
        self.assertGreaterEqual(len({r['payment_amount'] for r in self.rows['payment']}), 12)
        self.assertEqual(len({r['delivery_status'] for r in self.rows['shipment']}), 4)
        self.assertEqual(len({r['approval_status'] for r in self.rows['approval_process']}), 3)
        self.assertEqual(len({r['get_order_status'] for r in self.rows['get_order']}), 5)
