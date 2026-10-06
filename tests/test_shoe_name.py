import unittest
from unittest.mock import MagicMock, patch

from fastapi import FastAPI
from fastapi.testclient import TestClient

from routers.shoe import router
from services.checkout_service import complete_checkout, read_order_detail
from services.shoe_service import create_shoe, update_shoe


class ShoeNameApiTests(unittest.TestCase):
    def setUp(self):
        app = FastAPI()
        app.include_router(router)
        self.client = TestClient(app)
        self.conn = MagicMock()
        self.cursor = self.conn.cursor.return_value.__enter__.return_value
        self.cursor.fetchone.return_value = {"exists": 1}
        self.db_patch = patch("services._database.db", return_value=self.conn)
        self.db_patch.start()
        self.addCleanup(self.db_patch.stop)

    def test_create_accepts_korean_product_name_and_keeps_brand_separate(self):
        response = self.client.post(
            "/shoe/upload",
            data={
                "shoe_id": "airforce_black",
                "shoe_name": "에어포스 블랙",
                "brand_name": "NIKE",
                "shoe_category": "러닝",
            },
        )

        self.assertEqual(response.status_code, 200, response.text)
        sql, params = self.cursor.execute.call_args.args
        self.assertIn("`shoe_name`", sql)
        self.assertIn("에어포스 블랙", params)
        self.assertIn("NIKE", params)
        self.assertIn("러닝", params)
        self.conn.commit.assert_called_once()

    def test_name_only_update_preserves_other_product_fields(self):
        product_name = "에어포스 '블랙'"
        response = self.client.put(
            "/shoe/update/airforce_black", data={"shoe_name": product_name}
        )

        self.assertEqual(response.status_code, 200, response.text)
        sql, params = self.cursor.execute.call_args.args
        self.assertEqual(sql, "UPDATE `shoe` SET `shoe_name` = %s WHERE `shoe_id` = %s")
        self.assertEqual(params, (product_name, "airforce_black"))
        self.conn.commit.assert_called_once()

    def test_name_search_remains_combined_with_category_and_returns_name(self):
        self.cursor.fetchall.return_value = [
            {"shoe_id": "airforce_black", "shoe_name": "에어포스 블랙", "brand_name": "NIKE"}
        ]
        response = self.client.get(
            "/shoe/search", params={"query": " 에어포스 ", "category": " 러닝 "}
        )

        self.assertEqual(response.status_code, 200, response.text)
        self.assertEqual(response.json()["result"][0]["shoe_name"], "에어포스 블랙")
        sql, params = self.cursor.execute.call_args.args
        self.assertIn("(`shoe_id` LIKE %s OR `brand_name` LIKE %s OR `shoe_name` LIKE %s)", sql)
        self.assertIn(" AND `shoe_category` = %s", sql)
        self.assertEqual(params, ("%에어포스%", "%에어포스%", "%에어포스%", "러닝"))

    def test_name_length_is_checked_before_create_or_update_accesses_database(self):
        for method, path, required in (
            (self.client.post, "/shoe/upload", {"shoe_id": "airforce_black"}),
            (self.client.put, "/shoe/update/airforce_black", {}),
        ):
            with self.subTest(path=path):
                self.conn.reset_mock()
                response = method(path, data={**required, "shoe_name": "가" * 45})
                self.assertEqual(response.status_code, 200, response.text)
                self.conn.reset_mock()

                response = method(path, data={**required, "shoe_name": "가" * 46})

                self.assertEqual(response.status_code, 422, response.text)
                self.conn.cursor.assert_not_called()

    def test_existing_positional_service_calls_can_omit_product_name(self):
        create_shoe("sample", "NIKE", "러닝", None, "10000", 1, 5)
        sql, params = self.cursor.execute.call_args.args
        self.assertNotIn("`shoe_name`", sql)
        self.assertIn("NIKE", params)

        update_shoe("sample", "NIKE", "러닝", None, "10000", 1, 5)
        sql, params = self.cursor.execute.call_args.args
        self.assertNotIn("`shoe_name`", sql)
        self.assertIn("NIKE", params)


class ShoeNameOrderTests(unittest.TestCase):
    def product_cases(self):
        return (
            ({"shoe_name": "에어포스 블랙", "brand_name": "NIKE"}, "에어포스 블랙"),
            ({"brand_name": "NIKE"}, "NIKE"),
            ({"shoe_name": "", "brand_name": "NIKE"}, "NIKE"),
            ({"shoe_name": "   ", "brand_name": "NIKE"}, "NIKE"),
            ({}, "airforce_black"),
        )

    def test_order_detail_prefers_product_name_and_supports_old_records(self):
        for product, expected in self.product_cases():
            with self.subTest(product=product):
                conn = MagicMock()
                cursor = conn.cursor.return_value.__enter__.return_value
                cursor.fetchall.return_value = [{"shoe_shoe_id": "airforce_black", "quantity": "1"}]
                cursor.fetchone.side_effect = [product, None]
                with patch("services.checkout_service.db", return_value=conn):
                    result = read_order_detail("user", "order")

                self.assertEqual(result["result"]["items"][0]["name"], expected)
                conn.close.assert_called_once()

    def test_checkout_receipt_uses_the_same_name_and_fallbacks(self):
        for product, expected in self.product_cases():
            with self.subTest(product=product):
                conn = MagicMock()
                cursor = conn.cursor.return_value.__enter__.return_value
                cursor.fetchone.side_effect = [
                    {"exists": 1},
                    {"store_id": "store"},
                    {"employee_id": "employee"},
                    {"shoe_id": "airforce_black", "stock_quantity": 2, "shoe_price": "10000", **product},
                ]
                with patch("services.checkout_service.db", return_value=conn):
                    result = complete_checkout(
                        "user", "store", [{"shoe_id": "airforce_black", "quantity": 1}], "card", False
                    )

                self.assertEqual(result["result"]["items"][0]["shoe_name"], expected)
                self.assertEqual(result["result"]["total"], 10000)
                conn.commit.assert_called_once()
                conn.close.assert_called_once()


if __name__ == "__main__":
    unittest.main()
