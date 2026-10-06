"""Idempotent, additive schema preparation for Firestore shoe image imports.

MySQL DDL commits implicitly, so a failed migration can be rerun safely but
cannot be rolled back as a transaction. Existing foreign keys are retained.
"""

import re

import pymysql

from db.database import db


SHOE_ID_MAX_LENGTH = 45

_COLUMN_FIELDS = """
    TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH, CHARACTER_SET_NAME, COLLATION_NAME
"""


def _identifier(value: str) -> str:
    return "`" + value.replace("`", "``") + "`"


def _widen_statement(column: dict, create_table: str) -> str:
    """Change only the VARCHAR length in MySQL's own column definition.

    Keeping SHOW CREATE TABLE's definition preserves defaults (including SQL
    expressions), character set, collation, nullability, comments and extras.
    Omitted character-set attributes continue to inherit the unchanged table
    defaults. No data conversion or constraint replacement is involved.
    """
    prefix = _identifier(column["COLUMN_NAME"]) + " "
    for line in create_table.splitlines():
        line = line.lstrip()
        if not line.startswith(prefix):
            continue
        definition = line[len(prefix):].rstrip().removesuffix(",")
        definition, replaced = re.subn(
            r"^varchar\(\d+\)",
            f"VARCHAR({SHOE_ID_MAX_LENGTH})",
            definition,
            count=1,
            flags=re.IGNORECASE,
        )
        if replaced != 1:
            break
        table = (
            _identifier(column["TABLE_SCHEMA"])
            + "."
            + _identifier(column["TABLE_NAME"])
        )
        return f"ALTER TABLE {table} MODIFY COLUMN {prefix}{definition}"
    raise RuntimeError("Could not preserve a shoe identifier column definition")


def _execute_widen(cursor, sql: str) -> None:
    """Try compatible widening with FK checks enabled before a session retry.

    VARCHAR(20) to VARCHAR(45) retains the same length-byte representation,
    even with utf8mb4. MySQL permits this widening and different parent/child
    VARCHAR lengths. Some server configurations require FK checks disabled
    for the ALTER; this session performs only DDL and retains the constraints.
    """
    try:
        cursor.execute(sql)
    except pymysql.OperationalError as error:
        if not error.args or error.args[0] not in (1832, 1833):
            raise
        cursor.execute("SELECT @@SESSION.FOREIGN_KEY_CHECKS AS foreign_key_checks")
        original_checks = int(cursor.fetchone()["foreign_key_checks"])
        if original_checks == 0:
            raise
        try:
            cursor.execute("SET SESSION FOREIGN_KEY_CHECKS = 0")
            cursor.execute(sql)
        finally:
            cursor.execute(
                "SET SESSION FOREIGN_KEY_CHECKS = %s", (original_checks,)
            )


def ensure_shoe_schema() -> None:
    """Add image/category columns and widen shoe IDs plus referencing columns.

    All definitions are inspected before changing the schema. Existing columns
    at least 45 characters wide are left alone. Only short VARCHAR identifiers
    are migrated automatically; other identifier types need a manual migration.
    """
    conn = None
    try:
        conn = db()
        with conn.cursor(pymysql.cursors.DictCursor) as cursor:
            cursor.execute("SELECT DATABASE() AS schema_name")
            schema = cursor.fetchone()["schema_name"]
            if not schema:
                raise RuntimeError("Select a database before preparing the shoe schema")
            cursor.execute(
                f"SELECT {_COLUMN_FIELDS} FROM information_schema.COLUMNS "
                "WHERE TABLE_SCHEMA = %s AND TABLE_NAME = 'shoe'",
                (schema,),
            )
            shoe_columns = {row["COLUMN_NAME"]: row for row in cursor.fetchall()}
            if "shoe_id" not in shoe_columns:
                raise RuntimeError("The shoe table must have a shoe_id column")
            cursor.execute(
                "SELECT DISTINCT c.TABLE_SCHEMA, c.TABLE_NAME, c.COLUMN_NAME, "
                "c.DATA_TYPE, c.CHARACTER_MAXIMUM_LENGTH, "
                "c.CHARACTER_SET_NAME, c.COLLATION_NAME "
                "FROM information_schema.KEY_COLUMN_USAGE AS k "
                "JOIN information_schema.COLUMNS AS c "
                "ON c.TABLE_SCHEMA = k.TABLE_SCHEMA "
                "AND c.TABLE_NAME = k.TABLE_NAME "
                "AND c.COLUMN_NAME = k.COLUMN_NAME "
                "WHERE k.REFERENCED_TABLE_SCHEMA = %s "
                "AND k.REFERENCED_TABLE_NAME = 'shoe' "
                "AND k.REFERENCED_COLUMN_NAME = 'shoe_id' "
                "ORDER BY c.TABLE_SCHEMA, c.TABLE_NAME, c.COLUMN_NAME",
                (schema,),
            )
            columns = [shoe_columns["shoe_id"], *cursor.fetchall()]
            statements = []
            definitions = {}
            seen = set()
            for column in columns:
                key = (
                    column["TABLE_SCHEMA"],
                    column["TABLE_NAME"],
                    column["COLUMN_NAME"],
                )
                if key in seen:
                    continue
                seen.add(key)
                length = column["CHARACTER_MAXIMUM_LENGTH"]
                if length is not None and length >= SHOE_ID_MAX_LENGTH:
                    continue
                if column["DATA_TYPE"].lower() != "varchar" or length is None:
                    raise RuntimeError(
                        "Shoe identifier columns must be VARCHAR for automatic widening"
                    )
                table_key = key[:2]
                if table_key not in definitions:
                    table = ".".join(_identifier(part) for part in table_key)
                    cursor.execute(f"SHOW CREATE TABLE {table}")
                    definitions[table_key] = cursor.fetchone()["Create Table"]
                statements.append(
                    _widen_statement(column, definitions[table_key])
                )
            for statement in statements:
                _execute_widen(cursor, statement)

            for name, definition in (
                ("shoe_name", "VARCHAR(45) NULL AFTER `brand_name`"),
                ("shoe_category", "VARCHAR(45) NULL AFTER `brand_name`"),
                ("shoe_image_url", "TEXT NULL AFTER `shoe_category`"),
                ("shoe_img_url", "TEXT NULL AFTER `shoe_image_url`"),
            ):
                if name in shoe_columns:
                    continue
                table = _identifier(schema) + ".`shoe`"
                try:
                    cursor.execute(
                        f"ALTER TABLE {table} ADD COLUMN {_identifier(name)} {definition}"
                    )
                except pymysql.OperationalError as error:
                    # Another startup process may have added the same column.
                    if not error.args or error.args[0] != 1060:
                        raise
        conn.commit()
    except pymysql.MySQLError:
        if conn is not None:
            conn.rollback()
        raise RuntimeError(
            "Could not prepare the shoe schema; check database permissions and "
            "column definitions. MySQL may retain completed schema changes."
        ) from None
    finally:
        if conn is not None:
            conn.close()
