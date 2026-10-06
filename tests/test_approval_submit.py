import unittest
from unittest.mock import MagicMock, patch
import pymysql
from fastapi.testclient import TestClient
from main import app


class ApprovalSubmissionTests(unittest.TestCase):
    def setUp(self):
        self.conn = MagicMock()
        self.cursor = self.conn.cursor.return_value.__enter__.return_value
        self.cursor.fetchone.return_value = {'employee_id': 'e1'}
        self.client = TestClient(app)
        self.payload = {'approval_name': 'Proposal', 'approval_content': 'Reason',
                        'employee_employee_id': 'e1', 'requested_amount': '120000.50'}
        patcher = patch('services.approval_service.db', return_value=self.conn)
        patcher.start()
        self.addCleanup(patcher.stop)

    def test_saves_proposal_and_initial_process_in_one_transaction(self):
        response = self.client.post('/approval/submit', json=self.payload)
        self.assertEqual(response.status_code, 200, response.text)
        self.assertEqual(response.json()['approval_status'], '결재대기')
        self.assertEqual(response.json()['current_stage'], '팀장 결재 대기')
        self.assertLessEqual(len(response.json()['approval_id']), 20)
        calls = self.cursor.execute.call_args_list
        self.assertIn('requested_amount', calls[1].args[0])
        self.assertIn('INSERT INTO approval_process', calls[2].args[0])
        self.assertEqual(calls[2].args[1][-3:], ('대기', '대기', '결재대기'))
        self.conn.commit.assert_called_once()
        self.conn.close.assert_called_once()

    def test_invalid_amount_and_unknown_employee(self):
        response = self.client.post('/approval/submit', json={**self.payload, 'requested_amount': '-1'})
        self.assertEqual(response.status_code, 422)
        self.conn.cursor.assert_not_called()
        self.cursor.fetchone.return_value = None
        response = self.client.post('/approval/submit', json=self.payload)
        self.assertEqual(response.status_code, 422)
        self.conn.commit.assert_not_called()

    def test_process_failure_rolls_back_both_records(self):
        self.cursor.execute.side_effect = [None, None, pymysql.OperationalError(1, 'failure')]
        with self.assertLogs('services.approval_service', level='ERROR'):
            response = self.client.post('/approval/submit', json=self.payload)
        self.assertEqual(response.status_code, 500)
        self.conn.rollback.assert_called_once()
        self.conn.commit.assert_not_called()
