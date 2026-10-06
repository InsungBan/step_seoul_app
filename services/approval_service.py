from fastapi import HTTPException

from services._database import execute
from db.database import db
from datetime import datetime, timedelta, timezone
from decimal import Decimal
from uuid import uuid4
import pymysql
import logging


def submit_approval(title: str, content: str, employee_id: str, requested_amount: Decimal):
    """Save the proposal and initial approval process atomically."""
    conn = None
    ident = 'PR' + uuid4().hex[:18]
    process_id = 'AP' + uuid4().hex
    created = datetime.now(timezone(timedelta(hours=9))).strftime('%Y-%m-%d %H:%M:%S')
    try:
        conn = db()
        conn.begin()
        with conn.cursor(pymysql.cursors.DictCursor) as cursor:
            cursor.execute('SELECT employee_id FROM employee WHERE employee_id = %s FOR UPDATE', (employee_id,))
            if cursor.fetchone() is None:
                raise HTTPException(status_code=422, detail='Approval employee does not exist')
            cursor.execute(
                'INSERT INTO approval (approval_id, approval_name, approval_content, requested_amount) VALUES (%s, %s, %s, %s)',
                (ident, title, content, requested_amount),
            )
            cursor.execute(
                'INSERT INTO approval_process (employee_employee_id, approval_approval_id, approval_process_id, approval_date, team_leader_approval, director_approval, approval_status) VALUES (%s, %s, %s, %s, %s, %s, %s)',
                (employee_id, ident, process_id, created, '대기', '대기', '결재대기'),
            )
        conn.commit()
        return {'result': 'CREATE OK', 'approval_id': ident, 'approval_date': created,
                'requested_amount': requested_amount, 'employee_employee_id': employee_id,
                'current_stage': '팀장 결재 대기', 'approval_status': '결재대기'}
    except HTTPException:
        if conn is not None:
            conn.rollback()
        raise
    except pymysql.MySQLError:
        if conn is not None:
            conn.rollback()
        logging.getLogger(__name__).exception('Proposal submission failed')
        raise HTTPException(status_code=500, detail='Proposal submission failed') from None
    finally:
        if conn is not None:
            conn.close()


def create_approval(
    approval_id: str,
    approval_name: str | None,
    approval_content: str | None,
):
    data = {
        "approval_id": approval_id,
        "approval_name": approval_name,
        "approval_content": approval_content,
    }
    data = {name: value for name, value in data.items() if value is not None}
    columns = ", ".join(f"`{name}`" for name in data)
    placeholders = ", ".join("%s" for _ in data)
    sql = f"INSERT INTO `approval` ({columns}) VALUES ({placeholders})"
    return execute(sql, tuple(data.values()), action="CREATE")


def read_approval():
    return execute("SELECT * FROM `approval`")


def update_approval(
    approval_id: str,
    approval_name: str | None = None,
    approval_content: str | None = None,
):
    data = {
        "approval_name": approval_name,
        "approval_content": approval_content,
    }
    data = {name: value for name, value in data.items() if value is not None}
    if not data:
        raise HTTPException(status_code=422, detail="Provide at least one field to update")
    assignments = ", ".join(f"`{name}` = %s" for name in data)
    keys = (approval_id,)
    sql = f"UPDATE `approval` SET {assignments} WHERE `approval_id` = %s"
    return execute(sql, tuple(data.values()) + keys, action="UPDATE",
                   existence=("SELECT 1 FROM `approval` WHERE `approval_id` = %s FOR UPDATE", keys))


def delete_approval(
    approval_id: str,
):
    keys = (approval_id,)
    return execute("DELETE FROM `approval` WHERE `approval_id` = %s", keys, action="DELETE",
                   existence=("SELECT 1 FROM `approval` WHERE `approval_id` = %s FOR UPDATE", keys))
