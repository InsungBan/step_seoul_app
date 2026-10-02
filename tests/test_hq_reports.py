import unittest
from datetime import date
from unittest.mock import patch
from fastapi.testclient import TestClient
from main import app
from services.hq_service import build_reports, REPORTS, MISSING


class HqReportTests(unittest.TestCase):
    def fixture(self):
        return {
            'approval': [{'approval_id': 'a1', 'approval_name': 'Final review'}],
            'approval_process': [
                {'approval_approval_id': 'a1', 'team_leader_approval': '승인', 'director_approval': '대기', 'approval_status': '결재대기', 'approval_date': '2026-10-01 10:00:00'},
                {'approval_approval_id': 'a2', 'team_leader_approval': '대기', 'director_approval': '대기', 'approval_status': '결재대기'},
            ],
            'shoe': [
                {'shoe_id': 's1', 'shoe_category': '러닝화', 'standard_stock': 100, 'stock_quantity': 30},
                {'shoe_id': 's2', 'shoe_category': '러닝화', 'standard_stock': 100, 'stock_quantity': 31},
                {'shoe_id': 's3', 'shoe_category': '부츠', 'standard_stock': 0, 'stock_quantity': 0},
            ],
            'payment': [
                {'payment_id': 'p1', 'user_user_id': 'u1', 'payment_status': 1, 'payment_date': '2026-10-02 12:00:00'},
                {'payment_id': 'p2', 'user_user_id': 'u1', 'payment_status': 0, 'payment_date': '2026-10-02 12:00:00'},
                {'payment_id': 'p3', 'user_user_id': 'u1', 'payment_status': 1, 'payment_date': '2026-09-30 12:00:00'},
            ],
            'purchase': [
                {'payment_id': 'p1', 'user_user_id': 'u1', 'shoe_shoe_id': 's1', 'sale_price': '89000', 'quantity': '2'},
                {'payment_id': 'p2', 'user_user_id': 'u1', 'shoe_shoe_id': 's1', 'sale_price': '89000', 'quantity': '100'},
                {'payment_id': 'p3', 'user_user_id': 'u1', 'shoe_shoe_id': 's1', 'sale_price': '89000', 'quantity': '100'},
            ],
            'receive': [{'receive_id': 'r1', 'receive_status': '수령완료'}, {'receive_id': 'r2', 'receive_status': '수령대기'}],
        }

    def test_real_aggregates_and_inclusive_threshold(self):
        reports = build_reports(self.fixture(), date(2026, 10, 1), date(2026, 10, 2))
        self.assertEqual(len(reports['final-approvals']['result']), 1)
        self.assertEqual(reports['completed-receipts']['result'][0]['receive_id'], 'r1')
        self.assertEqual([r['shoe_id'] for r in reports['auto-order-targets']['result']], ['s1'])
        self.assertEqual(reports['inventory-by-category']['result'][0]['quantity'], 61)
        self.assertEqual(reports['sales-by-category']['result'][0]['amount'], 178000)
        for name in MISSING:
            self.assertFalse(reports[name]['available'])
            self.assertEqual(reports[name]['result'], [])
            self.assertTrue(reports[name]['requires'])

    def test_approved_latest_record_is_not_waiting(self):
        data = self.fixture()
        data['approval_process'].append({'approval_approval_id': 'a1', 'team_leader_approval': '승인', 'director_approval': '승인', 'approval_status': '승인', 'processed_at': '2026-10-02 13:00:00'})
        self.assertEqual(build_reports(data)['final-approvals']['result'], [])

    def test_all_routes_and_invalid_range(self):
        client = TestClient(app)
        with patch('routers.hq.read_snapshot', return_value={'result': self.fixture()}):
            for name in REPORTS:
                response = client.get(f'/hq/{name}/select?start=2026-10-01&end=2026-10-02')
                self.assertEqual(response.status_code, 200, name)
                self.assertIn('available', response.json())
        with patch('routers.hq.read_snapshot') as read:
            self.assertEqual(client.get('/hq/sales-by-category/select?start=2026-10-03&end=2026-10-02').status_code, 422)
            read.assert_not_called()
    def test_optional_schema_activates_remaining_aggregates(self):
        data = self.fixture()
        data['_hq_schema'] = [{
            'get_order': ['received_at', 'expected_delivery_at'],
            'stock_movement': ['movement_id', 'shoe_shoe_id', 'changed_at', 'quantity_delta', 'stock_after', 'reason'],
            'purchase_order': ['is_auto'],
            'return_record': ['purchase_purchase_id', 'return_quantity'],
            'purchase': ['store_store_id'],
        }]
        data['get_order'] = [
            {'get_order_quantity': '12', 'get_order_date': '2026-10-01 10:00:00', 'received_at': '2026-10-02 10:00:00', 'expected_delivery_at': '2026-10-01'},
            {'get_order_quantity': '8', 'get_order_date': '2026-10-02 10:00:00', 'received_at': None, 'expected_delivery_at': '2026-10-01'},
        ]
        data['stock_movement'] = [
            {'movement_id': 'm1', 'changed_at': '2026-10-01 10:00:00', 'quantity_delta': 12},
            {'movement_id': 'm2', 'changed_at': '2026-09-20 10:00:00', 'quantity_delta': 10},
        ]
        data['purchase_order'] = [{'order_id': 'o1', 'is_auto': 1, 'order_date': '2026-10-01'}]
        data['purchase'][0].update({'purchase_id': 'buy1', 'store_store_id': 'st1'})
        data['purchase'][1]['purchase_id'] = 'buy2'
        data['purchase'][2]['purchase_id'] = 'buy3'
        data['store'] = [{'store_id': 'st1', 'agency_name': 'Store'}]
        data['return_record'] = [{'purchase_purchase_id': 'buy1', 'return_quantity': '1', 'return_date': '2026-10-02 15:00:00'}]
        reports = build_reports(data, date(2026, 10, 1), date(2026, 10, 2), as_of=date(2026, 10, 2))
        self.assertEqual(reports['monthly-inbound']['result'][0]['quantity'], 20)
        self.assertEqual([r['movement_id'] for r in reports['stock-movements']['result']], ['m1'])
        self.assertEqual(reports['auto-order-history']['result'][0]['order_id'], 'o1')
        self.assertEqual(reports['return-rate']['result'][0]['rate'], 100)
        self.assertEqual(reports['sales-by-store']['result'][0]['amount'], 178000)
        self.assertEqual(reports['sales-by-store']['result'][0]['categories'][0]['amount'], 178000)
        self.assertTrue(all(reports[name]['available'] for name in MISSING))
