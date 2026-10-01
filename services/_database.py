import logging

import pymysql
from fastapi import HTTPException

from db.database import db

logger = logging.getLogger(__name__)


def execute(sql, params=(), action=None, existence=None):
    conn = None
    try:
        conn = db()
        with conn.cursor(pymysql.cursors.DictCursor) as curs:
            if existence is not None:
                curs.execute(*existence)
                if curs.fetchone() is None:
                    raise HTTPException(status_code=404, detail="Record not found")
            curs.execute(sql, params)
            if action is None:
                return {"result": list(curs.fetchall())}
        conn.commit()
        return {"result": f"{action} OK"}
    except HTTPException:
        if conn is not None:
            conn.rollback()
        raise
    except pymysql.IntegrityError:
        if conn is not None:
            conn.rollback()
        logger.exception("Database constraint error")
        raise HTTPException(status_code=409, detail="Duplicate key or foreign key constraint violation") from None
    except pymysql.MySQLError:
        if conn is not None:
            conn.rollback()
        logger.exception("Database operation failed")
        raise HTTPException(status_code=500, detail="Database operation failed; check the server log") from None
    finally:
        if conn is not None:
            conn.close()
