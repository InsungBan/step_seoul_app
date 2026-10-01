from fastapi import HTTPException

from services._database import execute


def create_return_record(
    shoe_shoe_id: str,
    employee_employee_id: str,
    return_id: str,
    return_date: str | None,
):
    data = {
        "shoe_shoe_id": shoe_shoe_id,
        "employee_employee_id": employee_employee_id,
        "return_id": return_id,
        "return_date": return_date,
    }
    data = {name: value for name, value in data.items() if value is not None}
    columns = ", ".join(f"`{name}`" for name in data)
    placeholders = ", ".join("%s" for _ in data)
    sql = f"INSERT INTO `return_record` ({columns}) VALUES ({placeholders})"
    return execute(sql, tuple(data.values()), action="CREATE")


def read_return_record():
    return execute("SELECT * FROM `return_record`")


def update_return_record(
    shoe_shoe_id: str,
    employee_employee_id: str,
    return_id: str,
    return_date: str | None = None,
):
    data = {
        "return_date": return_date,
    }
    data = {name: value for name, value in data.items() if value is not None}
    if not data:
        raise HTTPException(status_code=422, detail="Provide at least one field to update")
    assignments = ", ".join(f"`{name}` = %s" for name in data)
    keys = (shoe_shoe_id, employee_employee_id, return_id,)
    sql = f"UPDATE `return_record` SET {assignments} WHERE `shoe_shoe_id` = %s AND `employee_employee_id` = %s AND `return_id` = %s"
    return execute(sql, tuple(data.values()) + keys, action="UPDATE",
                   existence=("SELECT 1 FROM `return_record` WHERE `shoe_shoe_id` = %s AND `employee_employee_id` = %s AND `return_id` = %s FOR UPDATE", keys))


def delete_return_record(
    shoe_shoe_id: str,
    employee_employee_id: str,
    return_id: str,
):
    keys = (shoe_shoe_id, employee_employee_id, return_id,)
    return execute("DELETE FROM `return_record` WHERE `shoe_shoe_id` = %s AND `employee_employee_id` = %s AND `return_id` = %s", keys, action="DELETE",
                   existence=("SELECT 1 FROM `return_record` WHERE `shoe_shoe_id` = %s AND `employee_employee_id` = %s AND `return_id` = %s FOR UPDATE", keys))
