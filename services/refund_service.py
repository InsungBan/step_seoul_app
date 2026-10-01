from fastapi import HTTPException

from services._database import execute


def create_refund(
    user_user_id: str,
    employee_employee_id: str,
    refund_id: str,
    refund_amount: str | None,
    refund_quantity: str | None,
    refund_reason: str | None,
    refund_cardnumber: int | None,
):
    data = {
        "user_user_id": user_user_id,
        "employee_employee_id": employee_employee_id,
        "refund_id": refund_id,
        "refund_amount": refund_amount,
        "refund_quantity": refund_quantity,
        "refund_reason": refund_reason,
        "refund_cardnumber": refund_cardnumber,
    }
    data = {name: value for name, value in data.items() if value is not None}
    columns = ", ".join(f"`{name}`" for name in data)
    placeholders = ", ".join("%s" for _ in data)
    sql = f"INSERT INTO `refund` ({columns}) VALUES ({placeholders})"
    return execute(sql, tuple(data.values()), action="CREATE")


def read_refund():
    return execute("SELECT * FROM `refund`")


def update_refund(
    user_user_id: str,
    employee_employee_id: str,
    refund_id: str,
    refund_amount: str | None = None,
    refund_quantity: str | None = None,
    refund_reason: str | None = None,
    refund_cardnumber: int | None = None,
):
    data = {
        "refund_amount": refund_amount,
        "refund_quantity": refund_quantity,
        "refund_reason": refund_reason,
        "refund_cardnumber": refund_cardnumber,
    }
    data = {name: value for name, value in data.items() if value is not None}
    if not data:
        raise HTTPException(status_code=422, detail="Provide at least one field to update")
    assignments = ", ".join(f"`{name}` = %s" for name in data)
    keys = (user_user_id, employee_employee_id, refund_id,)
    sql = f"UPDATE `refund` SET {assignments} WHERE `user_user_id` = %s AND `employee_employee_id` = %s AND `refund_id` = %s"
    return execute(sql, tuple(data.values()) + keys, action="UPDATE",
                   existence=("SELECT 1 FROM `refund` WHERE `user_user_id` = %s AND `employee_employee_id` = %s AND `refund_id` = %s FOR UPDATE", keys))


def delete_refund(
    user_user_id: str,
    employee_employee_id: str,
    refund_id: str,
):
    keys = (user_user_id, employee_employee_id, refund_id,)
    return execute("DELETE FROM `refund` WHERE `user_user_id` = %s AND `employee_employee_id` = %s AND `refund_id` = %s", keys, action="DELETE",
                   existence=("SELECT 1 FROM `refund` WHERE `user_user_id` = %s AND `employee_employee_id` = %s AND `refund_id` = %s FOR UPDATE", keys))
