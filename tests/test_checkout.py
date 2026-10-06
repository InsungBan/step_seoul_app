import unittest
from unittest.mock import MagicMock, patch

from services.checkout_service import complete_checkout


class CheckoutTests(unittest.TestCase):
    def test_purchase_records_the_selected_store(self):
        conn = MagicMock()
        cursor = conn.cursor.return_value.__enter__.return_value
        cursor.fetchone.side_effect = [
            {"exists": 1},
            {"store_id": "store-1"},
            {"employee_id": "employee-1"},
            {
                "shoe_id": "airforce_black_m_280_00",
                "shoe_name": "에어포스 블랙",
                "stock_quantity": 30,
                "shoe_price": "139000",
            },
        ]

        with patch("services.checkout_service.db", return_value=conn):
            complete_checkout(
                user_id="user-1",
                store_id="store-1",
                items=[{"shoe_id": "airforce_black_m_280_00", "quantity": 1}],
                payment_method="card",
                clear_cart=False,
            )

        purchase_calls = [
            call
            for call in cursor.execute.call_args_list
            if "INSERT INTO `purchase`" in call.args[0]
        ]
        self.assertEqual(len(purchase_calls), 1)
        sql, params = purchase_calls[0].args
        self.assertIn("`store_store_id`", sql)
        self.assertEqual(params[-1], "store-1")
        self.assertEqual(sql.count("%s"), len(params))

        shipment_calls = [
            call
            for call in cursor.execute.call_args_list
            if "INSERT INTO `shipment`" in call.args[0]
        ]
        self.assertEqual(len(shipment_calls), 1)
        shipment_sql, shipment_params = shipment_calls[0].args
        self.assertIn("`purchase_purchase_id`", shipment_sql)
        self.assertEqual(shipment_params[-1], purchase_calls[0].args[1][2])
        self.assertEqual(shipment_sql.count("%s"), len(shipment_params))
        conn.commit.assert_called_once()


if __name__ == "__main__":
    unittest.main()
