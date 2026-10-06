import unittest
from unittest.mock import MagicMock, patch
import pymysql
from fastapi.testclient import TestClient
from main import app


class ShoeManufacturerCreateTests(unittest.TestCase):
    def setUp(self):
        self.conn = MagicMock()
        self.cursor = self.conn.cursor.return_value.__enter__.return_value
        self.cursor.fetchall.return_value = [{'manufacturer_id': 'm1'}]
        self.client = TestClient(app)
        self.payload = {'shoe_id': 's1', 'brand_name': 'Brand', 'manufacturer_name': '샘플 한빛슈즈'}
        patcher = patch('services.shoe_service.db', return_value=self.conn)
        patcher.start()
        self.addCleanup(patcher.stop)

    def test_creates_shoe_and_manufacturer_relationship(self):
        response = self.client.post('/shoe/upload', data=self.payload)
        self.assertEqual(response.status_code, 200, response.text)
        calls = self.cursor.execute.call_args_list
        self.assertEqual(calls[0].args[1], ('샘플 한빛슈즈',))
        self.assertIn('INSERT INTO `shoe`', calls[1].args[0])
        self.assertIn('INSERT INTO manufacturing', calls[2].args[0])
        self.assertEqual(calls[2].args[1][:2], ('s1', 'm1'))
        self.conn.commit.assert_called_once()

    def test_missing_duplicate_or_blank_manufacturer_is_rejected(self):
        for matches in ([], [{'manufacturer_id': 'm1'}, {'manufacturer_id': 'm2'}]):
            self.cursor.fetchall.return_value = matches
            response = self.client.post('/shoe/upload', data=self.payload)
            self.assertEqual(response.status_code, 422)
        response = self.client.post('/shoe/upload', data={**self.payload, 'manufacturer_name': '  '})
        self.assertEqual(response.status_code, 422)
        self.conn.commit.assert_not_called()

    def test_relationship_failure_rolls_back_shoe(self):
        self.cursor.execute.side_effect = [None, None, pymysql.OperationalError(1, 'failure')]
        with self.assertLogs('services.shoe_service', level='ERROR'):
            response = self.client.post('/shoe/upload', data=self.payload)
        self.assertEqual(response.status_code, 500)
        self.conn.rollback.assert_called_once()
        self.conn.commit.assert_not_called()
