from fastapi import HTTPException

from services._database import execute


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
