import unittest
from unittest.mock import MagicMock, patch

from fastapi import FastAPI
from fastapi.testclient import TestClient

from routers.shoe import router


class ShoeImageCompatibilityTests(unittest.TestCase):
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

    def assert_image_columns(self, image):
        sql, params = self.cursor.execute.call_args.args
        self.assertIn("`shoe_img_url`", sql)
        self.assertIn("`shoe_image_url`", sql)
        self.assertEqual(tuple(params).count(image), 2)
        self.assertEqual(sql.count("%s"), len(params))

    def test_canonical_image_field_and_requested_test_id_are_accepted(self):
        image = "https://example.test/canonical.png"

        response = self.client.post(
            "/shoe/upload", data={"shoe_id": "airforce_280_m_black_00", "shoe_img_url": image}
        )

        self.assertEqual(response.status_code, 200, response.text)
        self.assert_image_columns(image)

    def test_legacy_image_field_still_updates_both_columns(self):
        image = "https://example.test/legacy.png"

        response = self.client.put("/shoe/update/sample", data={"shoe_image_url": image})

        self.assertEqual(response.status_code, 200, response.text)
        self.assert_image_columns(image)

    def test_canonical_image_update_preserves_the_supplied_string(self):
        image = " https://example.test/image.png?token=a%2Bb "

        response = self.client.put("/shoe/update/sample", data={"shoe_img_url": image})

        self.assertEqual(response.status_code, 200, response.text)
        self.assert_image_columns(image)

    def test_matching_canonical_and_legacy_fields_are_accepted(self):
        image = "https://example.test/same.png"

        response = self.client.post(
            "/shoe/upload",
            data={"shoe_id": "sample", "shoe_img_url": image, "shoe_image_url": image},
        )

        self.assertEqual(response.status_code, 200, response.text)
        self.assert_image_columns(image)

    def test_conflicting_image_fields_reject_before_database_access(self):
        for method, path in (
            (self.client.post, "/shoe/upload"),
            (self.client.put, "/shoe/update/sample"),
        ):
            with self.subTest(path=path):
                response = method(
                    path,
                    data={"shoe_id": "sample", "shoe_img_url": "canonical", "shoe_image_url": "different"},
                )

                self.assertEqual(response.status_code, 422, response.text)
                self.conn.cursor.assert_not_called()

    def test_shoe_id_allows_45_characters_and_rejects_46(self):
        response = self.client.post("/shoe/upload", data={"shoe_id": "x" * 45})
        self.assertEqual(response.status_code, 200, response.text)
        self.conn.reset_mock()

        response = self.client.post("/shoe/upload", data={"shoe_id": "x" * 46})

        self.assertEqual(response.status_code, 422, response.text)
        self.conn.cursor.assert_not_called()


if __name__ == "__main__":
    unittest.main()
