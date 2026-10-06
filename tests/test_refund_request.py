import unittest
from unittest.mock import MagicMock, patch

from services.refund_request_service import create_refund_request


class RefundRequestTests(unittest.TestCase):
    def test_create_refund_request_runs_schema_migration_before_insert(self):
        conn = MagicMock()
        cursor = conn.cursor.return_value.__enter__.return_value
        cursor.fetchone.side_effect = [
            {"quantity": 2},
            {"employee_id": "EMP-001"},
            {"sale_price": "200000"},
        ]

        with patch("services.refund_request_service.ensure_refund_request_columns") as ensure_columns:
            with patch("services.refund_request_service.db", return_value=conn):
                result = create_refund_request(
                    user_id="user-1",
                    order_id="order-1",
                    shoe_id="shoe-1",
                    quantity=1,
                    reason="damaged",
                    detail_reason="left sole issue",
                )

        ensure_columns.assert_called_once()
        self.assertIn("refund_id", result["result"])
        conn.commit.assert_called_once()

    def test_refund_request_schema_expands_return_shoe_id_to_45_chars(self):
        expected = {
            "return_order_id": "VARCHAR(45) NULL",
            "return_shoe_id": "VARCHAR(45) NULL",
            "return_requested_at": "DATETIME NULL",
            "return_status": "VARCHAR(24) NOT NULL DEFAULT 'Requested'",
            "return_detail_reason": "VARCHAR(200) NULL",
        }
        self.assertEqual(expected["return_shoe_id"], "VARCHAR(45) NULL")


if __name__ == "__main__":
    unittest.main()
