from fastapi import HTTPException

from services._database import execute


def create_employee(
    employee_id: str,
    employee_pw: str | None,
    employee_position: str | None,
    employee_name: str | None,
    employee_department: str | None,
):
    # employee_id identifies a single employee. Return a clear conflict when an
    # upload is repeated instead of exposing a generic MySQL constraint error.
    existing_employee = execute(
        "SELECT 1 FROM `employee` WHERE `employee_id` = %s",
        (employee_id,),
    )["result"]
    if existing_employee:
        raise HTTPException(
            status_code=409,
            detail=(
                f"직원 ID '{employee_id}'는 이미 등록되어 있습니다. "
                "기존 직원 정보는 수정 API를 사용해 주세요."
            ),
        )

    data = {
        "employee_id": employee_id,
        "employee_pw": employee_pw,
        "employee_position": employee_position,
        "employee_name": employee_name,
        "employee_department": employee_department,
    }
    data = {name: value for name, value in data.items() if value is not None}
    columns = ", ".join(f"`{name}`" for name in data)
    placeholders = ", ".join("%s" for _ in data)
    sql = f"INSERT INTO `employee` ({columns}) VALUES ({placeholders})"
    return execute(sql, tuple(data.values()), action="CREATE")


def read_employee():
    return execute("SELECT * FROM `employee`")


def update_employee(
    employee_id: str,
    employee_pw: str | None = None,
    employee_position: str | None = None,
    employee_name: str | None = None,
    employee_department: str | None = None,
):
    data = {
        "employee_pw": employee_pw,
        "employee_position": employee_position,
        "employee_name": employee_name,
        "employee_department": employee_department,
    }
    data = {name: value for name, value in data.items() if value is not None}
    if not data:
        raise HTTPException(status_code=422, detail="Provide at least one field to update")
    assignments = ", ".join(f"`{name}` = %s" for name in data)
    keys = (employee_id,)
    sql = f"UPDATE `employee` SET {assignments} WHERE `employee_id` = %s"
    return execute(sql, tuple(data.values()) + keys, action="UPDATE",
                   existence=("SELECT 1 FROM `employee` WHERE `employee_id` = %s FOR UPDATE", keys))


def delete_employee(
    employee_id: str,
):
    keys = (employee_id,)
    return execute("DELETE FROM `employee` WHERE `employee_id` = %s", keys, action="DELETE",
                   existence=("SELECT 1 FROM `employee` WHERE `employee_id` = %s FOR UPDATE", keys))
