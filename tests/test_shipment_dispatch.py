import unittest
from unittest.mock import MagicMock, patch
from fastapi.testclient import TestClient
from main import app


class DispatchTests(unittest.TestCase):
    def setUp(self):
        self.conn = MagicMock()
        self.cursor = self.conn.cursor.return_value.__enter__.return_value
        self.cursor.fetchone.return_value = (1,)
        self.client = TestClient(app)
        self.row = {'shoe_shoe_id': 'airforce_black_m_280_00', 'employee_employee_id': 'e1',
                    'shipment_id': 'sh1', 'store_store_id': 'st1'}
        patcher = patch('services.shipment_service.db', return_value=self.conn)
        patcher.start()
        self.addCleanup(patcher.stop)

    def test_batch_updates_exact_status_and_all_composite_keys(self):
        response = self.client.put('/shipment/dispatch', json={'shipments': [self.row, {**self.row, 'shipment_id': 'sh2'}]})
        self.assertEqual(response.status_code, 200, response.text)
        self.assertEqual(response.json()['updated_count'], 2)
        updates = [call for call in self.cursor.execute.call_args_list if call.args[0].startswith('UPDATE')]
        self.assertEqual(len(updates), 2)
        self.assertEqual(updates[0].args[1][0], '배송 중')
        self.assertEqual(len(updates[0].args[1]), 5)
        self.conn.commit.assert_called_once()

    def test_missing_row_rolls_back_entire_batch(self):
        self.cursor.fetchone.side_effect = [(1,), None]
        response = self.client.put('/shipment/dispatch', json={'shipments': [self.row, {**self.row, 'shipment_id': 'sh2'}]})
        self.assertEqual(response.status_code, 404)
        self.conn.rollback.assert_called_once()
        self.conn.commit.assert_not_called()
        self.assertFalse(any(call.args[0].startswith('UPDATE') for call in self.cursor.execute.call_args_list))

    def test_empty_batch_is_rejected(self):
        self.assertEqual(self.client.put('/shipment/dispatch', json={'shipments': []}).status_code, 422)
        self.conn.cursor.assert_not_called()
