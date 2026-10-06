from fastapi import HTTPException

from services._database import execute
from db.database import db
import pymysql
import logging
from datetime import datetime, timezone, timedelta


def approve_by_employee(approval_id: str, employee_id: str):
    conn = None
    try:
        conn = db()
        conn.begin()
        with conn.cursor(pymysql.cursors.DictCursor) as cursor:
            cursor.execute('SELECT employee_position FROM employee WHERE employee_id = %s FOR UPDATE', (employee_id,))
            employee = cursor.fetchone()
            role = (employee or {}).get('employee_position', '').strip()
            if role not in ('팀장', '이사'):
                raise HTTPException(status_code=403, detail='Only team leaders and directors can approve')
            cursor.execute('SELECT * FROM approval_process WHERE approval_approval_id = %s ORDER BY COALESCE(processed_at, approval_date) DESC FOR UPDATE', (approval_id,))
            rows = cursor.fetchall()
            if not rows:
                raise HTTPException(status_code=404, detail='Approval process not found')
            row = rows[0]
            if len(rows) > 1 and (not (row.get('processed_at') or row.get('approval_date')) or
                (row.get('processed_at') or row.get('approval_date')) == (rows[1].get('processed_at') or rows[1].get('approval_date'))):
                raise HTTPException(status_code=409, detail='Latest approval process is ambiguous')
            approved = ('승인', '승인완료')
            if row.get('approval_status') not in ('결재대기', '결재중', '진행중'):
                raise HTTPException(status_code=409, detail='Approval is not pending')
            if role == '팀장':
                if row.get('team_leader_approval') in approved or row.get('director_approval') in approved:
                    raise HTTPException(status_code=409, detail='Team leader approval already processed')
                field, state = 'team_leader_approval', '결재중'
            else:
                if row.get('team_leader_approval') not in approved:
                    raise HTTPException(status_code=409, detail='Team leader approval is required first')
                if row.get('director_approval') in approved:
                    raise HTTPException(status_code=409, detail='Director approval already processed')
                field, state = 'director_approval', '승인완료'
            processed = datetime.now(timezone(timedelta(hours=9))).strftime('%Y-%m-%d %H:%M:%S')
            cursor.execute(
                f'UPDATE approval_process SET `{field}` = %s, approval_status = %s, processed_at = %s WHERE employee_employee_id = %s AND approval_approval_id = %s AND approval_process_id = %s',
                ('승인', state, processed, row['employee_employee_id'], approval_id, row['approval_process_id']),
            )
        conn.commit()
        return {'result': 'UPDATE OK', 'approved_role': role, 'approval_status': state}
    except HTTPException:
        if conn is not None:
            conn.rollback()
        raise
    except pymysql.MySQLError:
        if conn is not None:
            conn.rollback()
        logging.getLogger(__name__).exception('Role approval failed')
        raise HTTPException(status_code=500, detail='Approval failed') from None
    finally:
        if conn is not None:
            conn.close()


def create_approval_process(
    employee_employee_id: str,
    approval_approval_id: str,
    approval_process_id: str,
    approval_date: str | None,
    director_approval: str | None,
    team_leader_approval: str | None,
    approval_status: str | None,
    processed_at: str | None,
):
    data = {
        "employee_employee_id": employee_employee_id,
        "approval_approval_id": approval_approval_id,
        "approval_process_id": approval_process_id,
        "approval_date": approval_date,
        "director_approval": director_approval,
        "team_leader_approval": team_leader_approval,
        "approval_status": approval_status,
        "processed_at": processed_at,
    }
    data = {name: value for name, value in data.items() if value is not None}
    columns = ", ".join(f"`{name}`" for name in data)
    placeholders = ", ".join("%s" for _ in data)
    sql = f"INSERT INTO `approval_process` ({columns}) VALUES ({placeholders})"
    return execute(sql, tuple(data.values()), action="CREATE")


def read_approval_process():
    return execute("SELECT * FROM `approval_process`")


def update_approval_process(
    employee_employee_id: str,
    approval_approval_id: str,
    approval_process_id: str,
    approval_date: str | None = None,
    director_approval: str | None = None,
    team_leader_approval: str | None = None,
    approval_status: str | None = None,
    processed_at: str | None = None,
):
    data = {
        "approval_date": approval_date,
        "director_approval": director_approval,
        "team_leader_approval": team_leader_approval,
        "approval_status": approval_status,
        "processed_at": processed_at,
    }
    data = {name: value for name, value in data.items() if value is not None}
    if not data:
        raise HTTPException(status_code=422, detail="Provide at least one field to update")
    assignments = ", ".join(f"`{name}` = %s" for name in data)
    keys = (employee_employee_id, approval_approval_id, approval_process_id,)
    sql = f"UPDATE `approval_process` SET {assignments} WHERE `employee_employee_id` = %s AND `approval_approval_id` = %s AND `approval_process_id` = %s"
    return execute(sql, tuple(data.values()) + keys, action="UPDATE",
                   existence=("SELECT 1 FROM `approval_process` WHERE `employee_employee_id` = %s AND `approval_approval_id` = %s AND `approval_process_id` = %s FOR UPDATE", keys))


def delete_approval_process(
    employee_employee_id: str,
    approval_approval_id: str,
    approval_process_id: str,
):
    keys = (employee_employee_id, approval_approval_id, approval_process_id,)
    return execute("DELETE FROM `approval_process` WHERE `employee_employee_id` = %s AND `approval_approval_id` = %s AND `approval_process_id` = %s", keys, action="DELETE",
                   existence=("SELECT 1 FROM `approval_process` WHERE `employee_employee_id` = %s AND `approval_approval_id` = %s AND `approval_process_id` = %s FOR UPDATE", keys))
