from fastapi import HTTPException

from services._database import execute


def create_authentication(
    user_user_id: str,
    employee_employee_id: str,
    authentication_id: str,
    authentication_date: str | None,
):
    data = {
        "user_user_id": user_user_id,
        "employee_employee_id": employee_employee_id,
        "authentication_id": authentication_id,
        "authentication_date": authentication_date,
    }
    data = {name: value for name, value in data.items() if value is not None}
    columns = ", ".join(f"`{name}`" for name in data)
    placeholders = ", ".join("%s" for _ in data)
    sql = f"INSERT INTO `authentication` ({columns}) VALUES ({placeholders})"
    return execute(sql, tuple(data.values()), action="CREATE")


def read_authentication():
    return execute("SELECT * FROM `authentication`")


def update_authentication(
    user_user_id: str,
    employee_employee_id: str,
    authentication_id: str,
    authentication_date: str | None = None,
):
    data = {
        "authentication_date": authentication_date,
    }
    data = {name: value for name, value in data.items() if value is not None}
    if not data:
        raise HTTPException(status_code=422, detail="Provide at least one field to update")
    assignments = ", ".join(f"`{name}` = %s" for name in data)
    keys = (user_user_id, employee_employee_id, authentication_id,)
    sql = f"UPDATE `authentication` SET {assignments} WHERE `user_user_id` = %s AND `employee_employee_id` = %s AND `authentication_id` = %s"
    return execute(sql, tuple(data.values()) + keys, action="UPDATE",
                   existence=("SELECT 1 FROM `authentication` WHERE `user_user_id` = %s AND `employee_employee_id` = %s AND `authentication_id` = %s FOR UPDATE", keys))


def delete_authentication(
    user_user_id: str,
    employee_employee_id: str,
    authentication_id: str,
):
    keys = (user_user_id, employee_employee_id, authentication_id,)
    return execute("DELETE FROM `authentication` WHERE `user_user_id` = %s AND `employee_employee_id` = %s AND `authentication_id` = %s", keys, action="DELETE",
                   existence=("SELECT 1 FROM `authentication` WHERE `user_user_id` = %s AND `employee_employee_id` = %s AND `authentication_id` = %s FOR UPDATE", keys))
