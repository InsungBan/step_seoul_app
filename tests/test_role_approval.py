import unittest
from unittest.mock import MagicMock, patch
from fastapi.testclient import TestClient
from main import app


class RoleApprovalTests(unittest.TestCase):
    def setUp(self):
        self.client = TestClient(app)
        self.conn = MagicMock()
        self.cursor = self.conn.cursor.return_value.__enter__.return_value
        self.cursor.fetchone.return_value = {'employee_position': '팀장'}
        self.row = {'employee_employee_id': 'owner', 'approval_process_id': 'p1',
                    'approval_date': '2026-10-06 10:00:00', 'approval_status': '결재대기',
                    'team_leader_approval': '대기', 'director_approval': '대기'}
        self.cursor.fetchall.return_value = [self.row]
        patcher = patch('services.approval_process_service.db', return_value=self.conn)
        patcher.start()
        self.addCleanup(patcher.stop)

    def approve(self):
        return self.client.post('/approval_process/approve/a1', json={'employee_id': 'actor'})

    def test_team_leader_changes_only_team_leader_field(self):
        result = self.approve()
        self.assertEqual(result.status_code, 200)
        sql, params = self.cursor.execute.call_args.args
        self.assertIn('`team_leader_approval`', sql)
        self.assertNotIn('`director_approval`', sql)
        self.assertEqual(params[1], '결재중')
        self.assertEqual(params[3], 'owner')
        self.conn.commit.assert_called_once()

    def test_director_requires_team_leader_approval(self):
        self.cursor.fetchone.return_value = {'employee_position': '이사'}
        self.assertEqual(self.approve().status_code, 409)
        self.conn.commit.assert_not_called()
        self.row['team_leader_approval'] = '승인'
        self.assertEqual(self.approve().status_code, 200)
        sql, params = self.cursor.execute.call_args.args
        self.assertIn('`director_approval`', sql)
        self.assertEqual(params[1], '승인완료')

    def test_unauthorized_duplicate_and_rejected_approval(self):
        self.cursor.fetchone.return_value = {'employee_position': '사원'}
        self.assertEqual(self.approve().status_code, 403)
        self.cursor.fetchone.return_value = {'employee_position': '팀장'}
        self.row['team_leader_approval'] = '승인'
        self.assertEqual(self.approve().status_code, 409)
        self.row['approval_status'] = '반려'
        self.assertEqual(self.approve().status_code, 409)
        self.conn.commit.assert_not_called()
