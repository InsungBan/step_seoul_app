import unittest
from unittest.mock import MagicMock, patch

from fastapi import HTTPException

from services.authentication_service import authenticate_account
from services.password_service import hash_password, verify_password


class PasswordTests(unittest.TestCase):
    def test_hash_round_trip_and_wrong_password(self):
        encoded = hash_password("correct-password")

        self.assertTrue(encoded.startswith("pbkdf2_sha256$"))
        self.assertNotIn("correct-password", encoded)
        self.assertTrue(verify_password("correct-password", encoded))
        self.assertFalse(verify_password("wrong-password", encoded))


class AuthenticationTests(unittest.TestCase):
    def setUp(self):
        self.conn = MagicMock()
        self.cursor = self.conn.cursor.return_value.__enter__.return_value
        self.db_patch = patch(
            "services.authentication_service.db", return_value=self.conn
        )
        self.db_patch.start()
        self.addCleanup(self.db_patch.stop)

    def test_customer_login_returns_role_without_password(self):
        self.cursor.fetchone.return_value = {
            "account_id": "customer1",
            "password": hash_password("password123"),
        }

        result = authenticate_account("customer1", "password123")

        self.assertEqual(
            result, {"result": {"account_id": "customer1", "role": "customer"}}
        )
        self.assertNotIn("password", result["result"])
        self.conn.commit.assert_called_once()

    def test_head_office_employee_is_executive(self):
        self.cursor.fetchone.side_effect = [
            None,
            {
                "account_id": "executive1",
                "password": hash_password("password123"),
                "department": "본사",
            },
        ]

        result = authenticate_account("executive1", "password123")

        self.assertEqual(result["result"]["role"], "executive")

    def test_invalid_password_is_rejected(self):
        self.cursor.fetchone.return_value = {
            "account_id": "customer1",
            "password": hash_password("password123"),
        }

        with self.assertRaises(HTTPException) as context:
            authenticate_account("customer1", "wrong-password")

        self.assertEqual(context.exception.status_code, 401)
        self.conn.rollback.assert_called_once()


if __name__ == "__main__":
    unittest.main()
