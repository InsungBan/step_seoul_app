import unittest
from unittest.mock import MagicMock, patch
import pymysql
from fastapi.testclient import TestClient
from main import app
from routers.hq import COLUMNS


class HqSnapshotTests(unittest.TestCase):
    def test_snapshot_reads_database_and_omits_secrets(self):
        conn = MagicMock()
        cursor = conn.cursor.return_value.__enter__.return_value
        cursor.fetchall.side_effect = [[{'TABLE_NAME': t, 'COLUMN_NAME': c} for t, cols in COLUMNS.items() for c in cols]] + [[{columns[0]: 'db-row'}] for columns in COLUMNS.values()]
        with patch('routers.hq.db', return_value=conn):
            response = TestClient(app).get('/hq/snapshot')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(set(response.json()['result']), set(COLUMNS) | {"hq_reports", "_hq_schema"})
        self.assertEqual(response.json()['result']['shoe'], [{'shoe_id': 'db-row'}])
        sql = ' '.join(call.args[0] for call in cursor.execute.call_args_list)
        for secret in ('user_pw', 'employee_pw', 'receive_verification_code'):
            self.assertNotIn(secret, sql)
        conn.commit.assert_not_called()
        conn.rollback.assert_called_once()
        conn.close.assert_called_once()

    def test_database_failure_is_not_an_empty_success(self):
        with patch('routers.hq.db', side_effect=pymysql.OperationalError(2003, 'offline')):
            with self.assertLogs('routers.hq', level='ERROR'):
                response = TestClient(app).get('/hq/snapshot')
        self.assertEqual(response.status_code, 503)

    def test_local_flutter_web_cors(self):
        response = TestClient(app).options('/hq/snapshot', headers={
            'Origin': 'http://localhost:51324',
            'Access-Control-Request-Method': 'GET',
        })
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.headers['access-control-allow-origin'], 'http://localhost:51324')
