"""Password hashing and one-time migration for legacy account records."""

import base64
import hashlib
import hmac
import secrets

import pymysql

from db.database import db

ALGORITHM = "pbkdf2_sha256"
ITERATIONS = 310_000


def hash_password(password: str) -> str:
    if not password:
        raise ValueError("Password is required")
    salt = secrets.token_bytes(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, ITERATIONS)
    return "$".join(
        (
            ALGORITHM,
            str(ITERATIONS),
            base64.urlsafe_b64encode(salt).decode("ascii"),
            base64.urlsafe_b64encode(digest).decode("ascii"),
        )
    )


def verify_password(password: str, encoded: object) -> bool:
    stored = str(encoded or "")
    if not stored.startswith(f"{ALGORITHM}$"):
        return hmac.compare_digest(password, stored)
    try:
        algorithm, iterations, salt_value, digest_value = stored.split("$", 3)
        if algorithm != ALGORITHM:
            return False
        salt = base64.urlsafe_b64decode(salt_value.encode("ascii"))
        expected = base64.urlsafe_b64decode(digest_value.encode("ascii"))
        actual = hashlib.pbkdf2_hmac(
            "sha256", password.encode("utf-8"), salt, int(iterations)
        )
        return hmac.compare_digest(actual, expected)
    except (ValueError, TypeError):
        return False


def prepare_password_storage():
    """Widen password columns and hash any remaining legacy plaintext values."""
    conn = db()
    try:
        with conn.cursor(pymysql.cursors.DictCursor) as cursor:
            for table, id_column, password_column in (
                ("user", "user_id", "user_pw"),
                ("employee", "employee_id", "employee_pw"),
            ):
                cursor.execute(
                    "SELECT CHARACTER_MAXIMUM_LENGTH FROM information_schema.COLUMNS "
                    "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = %s "
                    "AND COLUMN_NAME = %s",
                    (table, password_column),
                )
                column = cursor.fetchone()
                if column is None or int(column["CHARACTER_MAXIMUM_LENGTH"] or 0) < 255:
                    cursor.execute(
                        f"ALTER TABLE `{table}` MODIFY COLUMN `{password_column}` VARCHAR(255) NULL"
                    )
                cursor.execute(
                    f"SELECT `{id_column}`, `{password_column}` FROM `{table}` "
                    f"WHERE `{password_column}` IS NOT NULL AND `{password_column}` <> ''"
                )
                for row in cursor.fetchall():
                    current = str(row[password_column])
                    if current.startswith(f"{ALGORITHM}$"):
                        continue
                    cursor.execute(
                        f"UPDATE `{table}` SET `{password_column}` = %s "
                        f"WHERE `{id_column}` = %s",
                        (hash_password(current), row[id_column]),
                    )
        conn.commit()
    except pymysql.MySQLError:
        conn.rollback()
        raise
    finally:
        conn.close()
