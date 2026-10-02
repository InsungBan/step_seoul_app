import json
import logging
from typing import Any

import pymysql
from fastapi import HTTPException

from db.database import db

logger = logging.getLogger(__name__)
_TABLE_SQL = """
CREATE TABLE IF NOT EXISTS employee_operations_state (
    scope_id VARCHAR(45) NOT NULL PRIMARY KEY,
    payload LONGTEXT NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
"""


def _open_connection():
    connection = db()
    try:
        with connection.cursor() as cursor:
            cursor.execute(_TABLE_SQL)
        return connection
    except Exception:
        connection.close()
        raise


def read_state(scope_id: str) -> dict[str, Any]:
    connection = None
    try:
        connection = _open_connection()
        with connection.cursor(pymysql.cursors.DictCursor) as cursor:
            cursor.execute(
                "SELECT payload, updated_at FROM employee_operations_state WHERE scope_id = %s",
                (scope_id,),
            )
            row = cursor.fetchone()
        if row is None:
            return {"scope_id": scope_id, "state": None, "updated_at": None}
        return {
            "scope_id": scope_id,
            "state": json.loads(row["payload"]),
            "updated_at": row["updated_at"].isoformat(),
        }
    except (pymysql.MySQLError, json.JSONDecodeError):
        logger.exception("Could not read employee operations state")
        raise HTTPException(status_code=500, detail="Could not read employee operations state") from None
    finally:
        if connection is not None:
            connection.close()


def write_state(scope_id: str, state: dict[str, Any]) -> dict[str, str]:
    connection = None
    try:
        payload = json.dumps(state, ensure_ascii=False, separators=(",", ":"))
        connection = _open_connection()
        with connection.cursor() as cursor:
            cursor.execute(
                """
                INSERT INTO employee_operations_state (scope_id, payload)
                VALUES (%s, %s)
                ON DUPLICATE KEY UPDATE
                    payload = VALUES(payload),
                    updated_at = CURRENT_TIMESTAMP
                """,
                (scope_id, payload),
            )
        connection.commit()
        return {"result": "saved", "scope_id": scope_id}
    except pymysql.MySQLError:
        if connection is not None:
            connection.rollback()
        logger.exception("Could not save employee operations state")
        raise HTTPException(status_code=500, detail="Could not save employee operations state") from None
    finally:
        if connection is not None:
            connection.close()
