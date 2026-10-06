import json
import unittest
from unittest.mock import MagicMock, patch
from urllib.error import HTTPError, URLError

import pymysql

from services.shoe_image_sync_service import (
    TEST_SHOE_ID,
    InvalidShoeImageError,
    ShoeImageSyncError,
    firestore_shoe_document_id,
    read_firestore_shoe_image,
    sync_shoe_images,
)


class FirestoreShoeDocumentIdTests(unittest.TestCase):
    def test_valid_variant_suffix_is_removed_from_product_id(self):
        cases = (
            ("airforce_black_m_280_00", "airforce_black"),
            ("air_force_special_black_f_250_01", "air_force_special_black"),
            ("airforce_black_u_270_02", "airforce_black"),
            ("airforce_black_M_280_00", "airforce_black"),
            ("airforce_black_F_250_01", "airforce_black"),
            ("airforce_black_U_270_02", "airforce_black"),
            ("airforce_m_280_00_m_300_01", "airforce_m_280_00"),
        )
        for shoe_id, product_id in cases:
            with self.subTest(shoe_id=shoe_id):
                self.assertEqual(firestore_shoe_document_id(shoe_id), product_id)

    def test_product_ids_and_invalid_variant_suffixes_are_preserved(self):
        shoe_ids = (
            "airforce_black",
            "air_force_special_black",
            "airforce_black_edition_280_00",
            "airforce_black_m_280",
            "airforce_black_m_280_",
            "airforce_black_m__00",
            "airforce_black__280_00",
            "airforce_black_x_280_00",
            "airforce_black_m_28.0_00",
            "airforce_black_m_280_seq",
            "airforce_black_m_+280_00",
            "airforce_black_m_ 280_00",
            "airforce_black_m_\u0662\u0668\u0660_00",
            "airforce_black_m_280_\uff10\uff10",
            "_m_280_00",
            "m_280_00",
        )
        for shoe_id in shoe_ids:
            with self.subTest(shoe_id=shoe_id):
                self.assertEqual(firestore_shoe_document_id(shoe_id), shoe_id)


class FirestoreShoeImageTests(unittest.TestCase):
    def setUp(self):
        self.urlopen_patch = patch("services.shoe_image_sync_service.urlopen")
        self.urlopen = self.urlopen_patch.start()
        self.addCleanup(self.urlopen_patch.stop)
        self.response = self.urlopen.return_value.__enter__.return_value

    def set_document(self, fields):
        self.response.read.return_value = json.dumps({"fields": fields}).encode("utf-8")

    def test_requested_variant_reads_product_document_and_preserves_the_string(self):
        url = " https://example.test/shoe.png?token=a%2Bb "
        self.set_document({"shoeImage": {"stringValue": url}})

        self.assertEqual(
            read_firestore_shoe_image(TEST_SHOE_ID, project_id="test-project"), url
        )

        args, kwargs = self.urlopen.call_args
        request_url = getattr(args[0], "full_url", args[0])
        self.assertIn("/projects/test-project/databases/(default)/documents/shoe/", request_url)
        self.assertTrue(request_url.endswith("/airforce_black"))
        self.assertEqual(kwargs["timeout"], 15)

    def test_reader_maps_multiple_underscores_and_keeps_product_ids(self):
        self.set_document({"shoeImage": {"stringValue": "image"}})
        cases = (
            ("air_force_special_black_F_250_01", "air_force_special_black"),
            ("airforce_black", "airforce_black"),
            ("airforce_black_m_280_sequence", "airforce_black_m_280_sequence"),
        )
        for shoe_id, document_id in cases:
            with self.subTest(shoe_id=shoe_id):
                read_firestore_shoe_image(shoe_id, project_id="test-project")

                request = self.urlopen.call_args.args[0]
                request_url = getattr(request, "full_url", request)
                self.assertTrue(request_url.endswith(f"/shoe/{document_id}"))

    def test_document_id_is_encoded_as_one_path_segment(self):
        self.set_document({"shoeImage": {"stringValue": "image"}})

        read_firestore_shoe_image("shoe/name?variant=1", project_id="test-project")

        request = self.urlopen.call_args.args[0]
        request_url = getattr(request, "full_url", request)
        self.assertTrue(request_url.endswith("/shoe%2Fname%3Fvariant%3D1"))

    def test_missing_document_returns_none(self):
        self.urlopen.side_effect = HTTPError("https://example.test", 404, "Not found", {}, None)

        self.assertIsNone(read_firestore_shoe_image(TEST_SHOE_ID, project_id="test-project"))

    def test_invalid_or_missing_shoe_image_is_rejected(self):
        invalid_fields = (
            {},
            {"shoeImage": {"integerValue": "123"}},
            {"shoeImage": {"stringValue": None}},
            {"shoeImage": {"stringValue": 123}},
            {"shoeImage": {"stringValue": ""}},
            {"shoeImage": {"stringValue": " \t\n "}},
        )
        for fields in invalid_fields:
            with self.subTest(fields=fields):
                self.set_document(fields)
                with self.assertRaises(InvalidShoeImageError):
                    read_firestore_shoe_image(TEST_SHOE_ID, project_id="test-project")

    def test_http_transport_and_json_errors_are_reported(self):
        for failure in (
            HTTPError("https://example.test", 403, "Forbidden", {}, None),
            HTTPError("https://example.test", 500, "Server error", {}, None),
            URLError("Network unavailable"),
            TimeoutError("Request timed out"),
        ):
            with self.subTest(failure=failure):
                self.urlopen.side_effect = failure
                with self.assertRaises(ShoeImageSyncError):
                    read_firestore_shoe_image(TEST_SHOE_ID, project_id="test-project")
        self.urlopen.side_effect = None
        self.response.read.return_value = b"not-json"
        with self.assertRaises(ShoeImageSyncError):
            read_firestore_shoe_image(TEST_SHOE_ID, project_id="test-project")


class ShoeImageSyncTests(unittest.TestCase):
    def setUp(self):
        self.conn = MagicMock()
        self.cursor = self.conn.cursor.return_value.__enter__.return_value
        self.cursor.fetchone.return_value = None
        self.cursor.fetchall.return_value = []
        self.db_patch = patch("services.shoe_image_sync_service.db", return_value=self.conn)
        self.db_patch.start()
        self.addCleanup(self.db_patch.stop)
        self.image_patch = patch("services.shoe_image_sync_service.read_firestore_shoe_image")
        self.image = self.image_patch.start()
        self.addCleanup(self.image_patch.stop)
        self.image.return_value = "https://example.test/image.png"

    def set_rows(self, *rows):
        self.cursor.fetchone.return_value = rows[0] if rows else None
        self.cursor.fetchall.return_value = list(rows)

    def mutations(self):
        return [
            call.args
            for call in self.cursor.execute.call_args_list
            if call.args[0].lstrip().upper().startswith(("INSERT", "UPDATE", "DELETE"))
        ]

    def assert_image_write(self, operation, shoe_id, image):
        mutations = self.mutations()
        self.assertEqual(len(mutations), 1)
        sql, params = mutations[0]
        self.assertTrue(sql.lstrip().upper().startswith(operation))
        self.assertIn("`shoe_img_url`", sql)
        self.assertIn("`shoe_image_url`", sql)
        self.assertIn(shoe_id, params)
        self.assertEqual(tuple(params).count(image), 2)
        self.assertEqual(sql.count("%s"), len(params))

    def test_explicit_test_record_creation_uses_exact_id_and_both_image_fields(self):
        image = " https://example.test/firestore-image.png "
        self.image.return_value = image

        result = sync_shoe_images(TEST_SHOE_ID, create_test_shoe=True, project_id="test-project")

        self.assertEqual(TEST_SHOE_ID, "airforce_black_m_280_00")
        self.assertEqual(result["created"], [TEST_SHOE_ID])
        self.assertEqual(result["updated"], [])
        self.assertFalse(result["dry_run"])
        self.image.assert_called_once_with(TEST_SHOE_ID, project_id="test-project")
        self.assert_image_write("INSERT", TEST_SHOE_ID, image)
        self.conn.cursor.assert_called_with(pymysql.cursors.DictCursor)
        self.conn.commit.assert_called_once()
        self.conn.close.assert_called_once()

    def test_existing_record_updates_image_columns_with_identical_string(self):
        self.set_rows({"shoe_id": TEST_SHOE_ID, "shoe_img_url": "old", "shoe_image_url": "old"})

        result = sync_shoe_images(TEST_SHOE_ID, project_id="test-project")

        self.assertEqual(result["updated"], [TEST_SHOE_ID])
        self.assertEqual(result["created"], [])
        self.assert_image_write("UPDATE", TEST_SHOE_ID, self.image.return_value)
        select_sql, select_params = self.cursor.execute.call_args_list[0].args
        self.assertIn("BINARY", select_sql.upper())
        self.assertEqual(select_params, (TEST_SHOE_ID,))

    def test_absent_mysql_row_is_not_created_without_explicit_test_flag(self):
        result = sync_shoe_images(TEST_SHOE_ID, project_id="test-project")

        self.assertEqual(result["created"], [])
        self.assertEqual(result["updated"], [])
        self.assertEqual(result["skipped"][0]["shoe_id"], TEST_SHOE_ID)
        self.assertEqual(self.mutations(), [])

    def test_bulk_sync_fetches_each_exact_mysql_id_and_skips_missing_document(self):
        self.set_rows(
            {"shoe_id": TEST_SHOE_ID, "shoe_img_url": "old", "shoe_image_url": "old"},
            {"shoe_id": "airforce_280_m_black_01", "shoe_img_url": "keep", "shoe_image_url": "keep"},
        )
        self.image.side_effect = lambda shoe_id, **kwargs: (
            "https://example.test/matched.png" if shoe_id == TEST_SHOE_ID else None
        )

        result = sync_shoe_images(project_id="test-project")

        self.assertEqual(result["updated"], [TEST_SHOE_ID])
        self.assertEqual(result["skipped"][0]["shoe_id"], "airforce_280_m_black_01")
        self.assertEqual(
            [call.args[0] for call in self.image.call_args_list],
            [TEST_SHOE_ID, "airforce_280_m_black_01"],
        )
        self.assert_image_write("UPDATE", TEST_SHOE_ID, "https://example.test/matched.png")

    def test_bulk_variants_share_product_image_and_update_each_full_mysql_id(self):
        variant_ids = (TEST_SHOE_ID, "airforce_black_f_250_01")
        image = " https://example.test/airforce-black.png?token=a%2Bb "
        self.set_rows(*(
            {"shoe_id": shoe_id, "shoe_img_url": "old", "shoe_image_url": "old"}
            for shoe_id in variant_ids
        ))
        self.image.side_effect = read_firestore_shoe_image
        with patch("services.shoe_image_sync_service.urlopen") as urlopen:
            response = urlopen.return_value.__enter__.return_value
            response.read.return_value = json.dumps(
                {"fields": {"shoeImage": {"stringValue": image}}}
            ).encode("utf-8")

            result = sync_shoe_images(project_id="test-project")

        self.assertEqual(result["updated"], list(variant_ids))
        self.assertEqual(result["created"], [])
        self.assertEqual(result["skipped"], [])
        self.assertEqual([call.args[0] for call in self.image.call_args_list], list(variant_ids))
        self.assertEqual(urlopen.call_count, 2)
        for call in urlopen.call_args_list:
            request_url = getattr(call.args[0], "full_url", call.args[0])
            self.assertTrue(request_url.endswith("/shoe/airforce_black"))
        mutations = self.mutations()
        self.assertEqual(len(mutations), 2)
        for (sql, params), shoe_id in zip(mutations, variant_ids):
            self.assertTrue(sql.startswith("UPDATE `shoe`"))
            self.assertIn("WHERE BINARY `shoe_id` = BINARY %s", sql)
            self.assertEqual(params, (image, image, shoe_id))
            self.assertNotIn("airforce_black", params)
        self.conn.commit.assert_called_once()

    def test_missing_or_invalid_firestore_image_keeps_existing_values(self):
        self.set_rows({"shoe_id": TEST_SHOE_ID, "shoe_img_url": "keep", "shoe_image_url": "keep"})
        for value in (None, InvalidShoeImageError("shoeImage must be a nonblank string")):
            with self.subTest(value=value):
                self.cursor.execute.reset_mock()
                if isinstance(value, Exception):
                    self.image.side_effect = value
                else:
                    self.image.side_effect = None
                    self.image.return_value = value

                result = sync_shoe_images(TEST_SHOE_ID, project_id="test-project")

                self.assertEqual(result["updated"], [])
                self.assertEqual(result["skipped"][0]["shoe_id"], TEST_SHOE_ID)
                self.assertEqual(self.mutations(), [])

    def test_missing_or_invalid_document_does_not_create_test_row(self):
        for value in (None, InvalidShoeImageError("missing shoeImage")):
            with self.subTest(value=value):
                self.cursor.execute.reset_mock()
                self.image.side_effect = value if isinstance(value, Exception) else None
                self.image.return_value = None

                result = sync_shoe_images(TEST_SHOE_ID, create_test_shoe=True, project_id="test-project")

                self.assertEqual(result["created"], [])
                self.assertEqual(result["skipped"][0]["shoe_id"], TEST_SHOE_ID)
                self.assertEqual(self.mutations(), [])

    def test_already_synced_record_is_unchanged_and_has_no_write(self):
        image = self.image.return_value
        self.set_rows({"shoe_id": TEST_SHOE_ID, "shoe_img_url": image, "shoe_image_url": image})

        result = sync_shoe_images(TEST_SHOE_ID, project_id="test-project")

        self.assertEqual(result["unchanged"], [TEST_SHOE_ID])
        self.assertEqual(result["updated"], [])
        self.assertEqual(self.mutations(), [])

    def test_legacy_column_difference_is_repaired(self):
        self.set_rows({"shoe_id": TEST_SHOE_ID, "shoe_img_url": self.image.return_value, "shoe_image_url": "old"})

        result = sync_shoe_images(TEST_SHOE_ID, project_id="test-project")

        self.assertEqual(result["updated"], [TEST_SHOE_ID])
        self.assert_image_write("UPDATE", TEST_SHOE_ID, self.image.return_value)

    def test_dry_run_reports_creation_without_mutating(self):
        result = sync_shoe_images(TEST_SHOE_ID, create_test_shoe=True, dry_run=True, project_id="test-project")

        self.assertTrue(result["dry_run"])
        self.assertEqual(result["created"], [TEST_SHOE_ID])
        self.assertEqual(self.mutations(), [])
        self.conn.commit.assert_not_called()
        self.conn.rollback.assert_called_once()
        self.conn.close.assert_called_once()

    def test_dry_run_reports_update_without_mutating(self):
        self.set_rows({"shoe_id": TEST_SHOE_ID, "shoe_img_url": "old", "shoe_image_url": "old"})

        result = sync_shoe_images(TEST_SHOE_ID, dry_run=True, project_id="test-project")

        self.assertEqual(result["updated"], [TEST_SHOE_ID])
        self.assertEqual(self.mutations(), [])
        self.conn.commit.assert_not_called()
        self.conn.rollback.assert_called_once()

    def test_database_failure_rolls_back_and_does_not_commit(self):
        self.set_rows({"shoe_id": TEST_SHOE_ID, "shoe_img_url": "old", "shoe_image_url": "old"})
        self.cursor.execute.side_effect = [None, pymysql.OperationalError(1205, "Lock timeout")]

        with self.assertRaises((pymysql.MySQLError, ShoeImageSyncError)):
            sync_shoe_images(TEST_SHOE_ID, project_id="test-project")

        self.conn.rollback.assert_called_once()
        self.conn.commit.assert_not_called()
        self.conn.close.assert_called_once()

    def test_firestore_failure_rolls_back_prior_updates(self):
        self.set_rows(
            {"shoe_id": TEST_SHOE_ID, "shoe_img_url": "old", "shoe_image_url": "old"},
            {"shoe_id": "second-shoe", "shoe_img_url": "keep", "shoe_image_url": "keep"},
        )
        self.image.side_effect = [self.image.return_value, ShoeImageSyncError("Firestore unavailable")]

        with self.assertRaises(ShoeImageSyncError):
            sync_shoe_images(project_id="test-project")

        self.assertEqual(len(self.mutations()), 1)
        self.conn.rollback.assert_called_once()
        self.conn.commit.assert_not_called()
        self.conn.close.assert_called_once()


if __name__ == "__main__":
    unittest.main()
