import unittest
from unittest.mock import MagicMock, patch

import pymysql

from services.shoe_schema import ensure_shoe_schema


def column(table, name, length=20, schema="step"):
    return {
        "TABLE_SCHEMA": schema,
        "TABLE_NAME": table,
        "COLUMN_NAME": name,
        "DATA_TYPE": "varchar",
        "CHARACTER_MAXIMUM_LENGTH": length,
        "CHARACTER_SET_NAME": "utf8mb4",
        "COLLATION_NAME": "utf8mb4_unicode_ci",
    }


class ShoeSchemaTests(unittest.TestCase):
    def setUp(self):
        self.conn = MagicMock()
        self.cursor = self.conn.cursor.return_value.__enter__.return_value
        self.result = None
        self.alters = []
        self.existing = [column("shoe", "shoe_id")]
        self.children = [column("cart", "shoe_shoe_id")]
        self.create_tables = {
            "shoe": (
                "CREATE TABLE `shoe` (\n"
                "  `shoe_id` varchar(20) CHARACTER SET utf8mb4 "
                "COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'default_id' "
                "COMMENT 'keep this, too',\n"
                "  PRIMARY KEY (`shoe_id`)\n)"
            ),
            "cart": (
                "CREATE TABLE `cart` (\n"
                "  `shoe_shoe_id` varchar(20) COLLATE utf8mb4_unicode_ci "
                "DEFAULT NULL,\n"
                "  CONSTRAINT `keep_fk` FOREIGN KEY (`shoe_shoe_id`) "
                "REFERENCES `shoe` (`shoe_id`) ON DELETE CASCADE\n)"
            ),
        }
        self.cursor.execute.side_effect = self.execute
        self.cursor.fetchone.side_effect = lambda: self.result
        self.cursor.fetchall.side_effect = lambda: self.result
        self.db_patch = patch("services.shoe_schema.db", return_value=self.conn)
        self.db_patch.start()
        self.addCleanup(self.db_patch.stop)

    def execute(self, sql, params=()):
        if sql == "SELECT DATABASE() AS schema_name":
            self.result = {"schema_name": "step"}
        elif "FROM information_schema.COLUMNS" in sql:
            self.result = self.existing
        elif "KEY_COLUMN_USAGE" in sql:
            self.result = self.children
        elif sql.startswith("SHOW CREATE TABLE"):
            table = "cart" if "`cart`" in sql else "shoe"
            self.result = {"Create Table": self.create_tables[table]}
        elif sql.startswith("ALTER TABLE"):
            self.alters.append(sql)
        elif sql.startswith("SELECT @@SESSION.FOREIGN_KEY_CHECKS"):
            self.result = {"foreign_key_checks": 1}
        return 1

    def test_widens_parent_and_children_preserving_definitions_and_foreign_keys(self):
        ensure_shoe_schema()
        self.assertIn(
            "MODIFY COLUMN `shoe_id` VARCHAR(45) CHARACTER SET utf8mb4 "
            "COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'default_id' "
            "COMMENT 'keep this, too'",
            self.alters[0],
        )
        self.assertIn(
            "MODIFY COLUMN `shoe_shoe_id` VARCHAR(45) COLLATE "
            "utf8mb4_unicode_ci DEFAULT NULL",
            self.alters[1],
        )
        self.assertTrue(any("ADD COLUMN `shoe_img_url` TEXT NULL" in sql for sql in self.alters))
        self.assertTrue(any("ADD COLUMN `shoe_name` VARCHAR(45) NULL AFTER `brand_name`" in sql for sql in self.alters))
        self.assertFalse(any("DROP" in sql for sql in self.alters))
        self.assertFalse(any("FOREIGN_KEY_CHECKS" in call.args[0] for call in self.cursor.execute.call_args_list))
        self.conn.commit.assert_called_once()
        self.conn.close.assert_called_once()

    def test_existing_wider_identifiers_and_image_columns_are_unchanged(self):
        self.existing = [
            column("shoe", "shoe_id", 60),
            column("shoe", "shoe_name", 45),
            column("shoe", "shoe_category", 45),
            column("shoe", "shoe_image_url"),
            column("shoe", "shoe_img_url"),
        ]
        self.children = [column("cart", "shoe_shoe_id", 45)]
        ensure_shoe_schema()
        self.assertEqual(self.alters, [])
        self.conn.close.assert_called_once()

    def test_restores_foreign_key_checks_when_retry_fails(self):
        alter_attempts = 0

        def fail(sql, params=()):
            nonlocal alter_attempts
            if sql.startswith("ALTER TABLE"):
                alter_attempts += 1
                if alter_attempts == 1:
                    raise pymysql.OperationalError(1833, "requires FK retry")
                raise pymysql.OperationalError(1142, "private database detail")
            return self.execute(sql, params)

        self.cursor.execute.side_effect = fail
        with self.assertRaises(RuntimeError) as raised:
            ensure_shoe_schema()
        self.assertNotIn("private database detail", str(raised.exception))
        self.cursor.execute.assert_any_call("SET SESSION FOREIGN_KEY_CHECKS = 0")
        self.cursor.execute.assert_any_call("SET SESSION FOREIGN_KEY_CHECKS = %s", (1,))
        self.conn.rollback.assert_called_once()
        self.conn.commit.assert_not_called()
        self.conn.close.assert_called_once()

    def test_rejects_unsupported_identifier_before_any_schema_mutation(self):
        self.children[0]["DATA_TYPE"] = "char"
        with self.assertRaisesRegex(RuntimeError, "must be VARCHAR"):
            ensure_shoe_schema()
        self.assertEqual(self.alters, [])
        self.conn.close.assert_called_once()


if __name__ == "__main__":
    unittest.main()
