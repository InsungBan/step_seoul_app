import json
import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch

import pymysql
from fastapi.testclient import TestClient

from main import app


class CrudApiTests(unittest.TestCase):
    def setUp(self):
        self.client = TestClient(app)
        self.conn = MagicMock()
        self.cursor = self.conn.cursor.return_value.__enter__.return_value
        self.cursor.fetchone.return_value = {"exists": 1}
        self.cursor.fetchall.return_value = []
        self.db_patch = patch("services._database.db", return_value=self.conn)
        self.db_patch.start()
        self.addCleanup(self.db_patch.stop)

    def test_all_table_operations_and_composite_keys(self):
        schema = json.loads(
            (Path(__file__).resolve().parents[1] / "db/schema.json").read_text(
                encoding="utf-8"
            )
        )
        tables = {}
        for column in schema["columns"]:
            tables.setdefault(column["TABLE_NAME"], []).append(column)
        for table, columns in tables.items():
            with self.subTest(table=table):
                self.conn.reset_mock()
                values = {
                    c["COLUMN_NAME"]: (
                        "1" if c["DATA_TYPE"] in ("int", "tinyint", "decimal")
                        else "sample"
                    )
                    for c in columns
                }
                keys = [c["COLUMN_NAME"] for c in columns if c["COLUMN_KEY"] == "PRI"]
                path = "/".join(values[key] for key in keys)
                response = self.client.post(f"/{table}/upload", data=values)
                self.assertEqual(response.status_code, 200, response.text)
                self.assertEqual(response.json(), {"result": "CREATE OK"})
                sql, params = self.cursor.execute.call_args.args
                self.assertTrue(sql.startswith(f"INSERT INTO `{table}`"))
                self.assertEqual(sql.count("%s"), len(params))
                response = self.client.get(f"/{table}/select")
                self.assertEqual(response.json(), {"result": []})
                non_keys = {k: v for k, v in values.items() if k not in keys}
                response = self.client.put(f"/{table}/update/{path}", data=non_keys)
                self.assertEqual(response.status_code, 200, response.text)
                self.assertEqual(response.json(), {"result": "UPDATE OK"})
                sql, params = self.cursor.execute.call_args.args
                for key in keys:
                    self.assertIn(f"`{key}` = %s", sql.split("WHERE")[1])
                self.assertEqual(sql.count("%s"), len(params))
                response = self.client.delete(f"/{table}/delete/{path}")
                self.assertEqual(response.json(), {"result": "DELETE OK"})
                sql, params = self.cursor.execute.call_args.args
                self.assertIsInstance(params, tuple)
                self.assertEqual(len(params), len(keys))
                self.assertEqual(sql.count("%s"), len(keys))
                self.assertEqual(self.conn.commit.call_count, 3)
                self.assertEqual(self.conn.close.call_count, 4)

    def test_missing_record_and_empty_update(self):
        self.cursor.fetchone.return_value = None
        response = self.client.delete("/user/delete/missing")
        self.assertEqual(response.status_code, 404)
        self.conn.rollback.assert_called_once()
        self.conn.commit.assert_not_called()
        response = self.client.put("/user/update/missing", data={})
        self.assertEqual(response.status_code, 422)

    def test_shipment_order_link_validates_product_and_saves(self):
        order_id = 'ORD-20261006-857D86F6'
        self.cursor.fetchall.return_value = [{'purchase_id': order_id}]
        payload = {'shoe_shoe_id': 'shoe1', 'employee_employee_id': 'employee1',
                   'shipment_id': 'shipment1', 'store_store_id': 'store1',
                   'purchase_purchase_id': order_id}
        response = self.client.post('/shipment/upload', data=payload)
        self.assertEqual(response.status_code, 200, response.text)
        sql, params = self.cursor.execute.call_args.args
        self.assertIn('purchase_purchase_id', sql)
        self.assertIn(order_id, params)
        self.cursor.fetchall.return_value = []
        self.conn.reset_mock()
        response = self.client.post('/shipment/upload', data=payload)
        self.assertEqual(response.status_code, 422)
        self.conn.commit.assert_not_called()


    def test_input_validation_prevents_database_access(self):
        response = self.client.post("/user/upload", data={"user_id": "x" * 13})
        self.assertEqual(response.status_code, 422)
        response = self.client.put("/shoe/update/sample", data={"stock_quantity": "abc"})
        self.assertEqual(response.status_code, 422)
        self.conn.cursor.assert_not_called()

    def test_return_refund_link_create_update_and_invalid_ids(self):
        self.cursor.fetchall.return_value = [{'refund_id': 'refund1'}]
        payload = {'shoe_shoe_id': 'shoe1', 'employee_employee_id': 'employee1',
                   'return_id': 'return1', 'refund_refund_id': 'refund1'}
        response = self.client.post('/return_record/upload', data=payload)
        self.assertEqual(response.status_code, 200, response.text)
        self.assertIn('refund_refund_id', self.cursor.execute.call_args.args[0])
        response = self.client.put('/return_record/update/shoe1/employee1/return1',
                                   data={'refund_refund_id': 'refund1'})
        self.assertEqual(response.status_code, 200, response.text)
        self.assertEqual(self.cursor.execute.call_args.args[1][0], 'refund1')
        for matches in ([], [{'refund_id': 'refund1'}, {'refund_id': 'refund1'}]):
            self.conn.reset_mock()
            self.cursor.fetchall.return_value = matches
            response = self.client.post('/return_record/upload', data=payload)
            self.assertEqual(response.status_code, 422)
            self.conn.commit.assert_not_called()
            self.conn.rollback.assert_called_once()

    def test_constraint_error_rolls_back(self):
        self.cursor.execute.side_effect = pymysql.IntegrityError(1062, "Duplicate")
        with self.assertLogs("services._database", level="ERROR"):
            response = self.client.post("/user/upload", data={"user_id": "sample"})
        self.assertEqual(response.status_code, 409)
        self.conn.rollback.assert_called_once()
        self.conn.close.assert_called_once()
        self.conn.commit.assert_not_called()


if __name__ == "__main__":
    unittest.main()
