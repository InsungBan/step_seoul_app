from fastapi import HTTPException

from services._database import execute


def create_recall(
    store_store_id: str,
    user_user_id: str,
    recall_id: str | None,
    recall_date: str | None,
    recall_quantity: int | None,
    employee_employee_id: str,
):
    data = {
        "store_store_id": store_store_id,
        "user_user_id": user_user_id,
        "recall_id": recall_id,
        "recall_date": recall_date,
        "recall_quantity": recall_quantity,
        "employee_employee_id": employee_employee_id,
    }
    data = {name: value for name, value in data.items() if value is not None}
    columns = ", ".join(f"`{name}`" for name in data)
    placeholders = ", ".join("%s" for _ in data)
    sql = f"INSERT INTO `recall` ({columns}) VALUES ({placeholders})"
    return execute(sql, tuple(data.values()), action="CREATE")


def read_recall():
    return execute("SELECT * FROM `recall`")


def update_recall(
    store_store_id: str,
    user_user_id: str,
    employee_employee_id: str,
    recall_id: str | None = None,
    recall_date: str | None = None,
    recall_quantity: int | None = None,
):
    data = {
        "recall_id": recall_id,
        "recall_date": recall_date,
        "recall_quantity": recall_quantity,
    }
    data = {name: value for name, value in data.items() if value is not None}
    if not data:
        raise HTTPException(status_code=422, detail="Provide at least one field to update")
    assignments = ", ".join(f"`{name}` = %s" for name in data)
    keys = (store_store_id, user_user_id, employee_employee_id,)
    sql = f"UPDATE `recall` SET {assignments} WHERE `store_store_id` = %s AND `user_user_id` = %s AND `employee_employee_id` = %s"
    return execute(sql, tuple(data.values()) + keys, action="UPDATE",
                   existence=("SELECT 1 FROM `recall` WHERE `store_store_id` = %s AND `user_user_id` = %s AND `employee_employee_id` = %s FOR UPDATE", keys))


def delete_recall(
    store_store_id: str,
    user_user_id: str,
    employee_employee_id: str,
):
    keys = (store_store_id, user_user_id, employee_employee_id,)
    return execute("DELETE FROM `recall` WHERE `store_store_id` = %s AND `user_user_id` = %s AND `employee_employee_id` = %s", keys, action="DELETE",
                   existence=("SELECT 1 FROM `recall` WHERE `store_store_id` = %s AND `user_user_id` = %s AND `employee_employee_id` = %s FOR UPDATE", keys))
