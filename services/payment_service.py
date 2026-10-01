from fastapi import HTTPException

from services._database import execute


def create_payment(
    user_user_id: str,
    employee_employee_id: str,
    payment_id: str,
    payment_date: str | None,
    payment_amount: int | None,
    payment_status: int | None,
    discount_flag: str | None,
):
    data = {
        "user_user_id": user_user_id,
        "employee_employee_id": employee_employee_id,
        "payment_id": payment_id,
        "payment_date": payment_date,
        "payment_amount": payment_amount,
        "payment_status": payment_status,
        "discount_flag": discount_flag,
    }
    data = {name: value for name, value in data.items() if value is not None}
    columns = ", ".join(f"`{name}`" for name in data)
    placeholders = ", ".join("%s" for _ in data)
    sql = f"INSERT INTO `payment` ({columns}) VALUES ({placeholders})"
    return execute(sql, tuple(data.values()), action="CREATE")


def read_payment():
    return execute("SELECT * FROM `payment`")


def update_payment(
    user_user_id: str,
    employee_employee_id: str,
    payment_id: str,
    payment_date: str | None = None,
    payment_amount: int | None = None,
    payment_status: int | None = None,
    discount_flag: str | None = None,
):
    data = {
        "payment_date": payment_date,
        "payment_amount": payment_amount,
        "payment_status": payment_status,
        "discount_flag": discount_flag,
    }
    data = {name: value for name, value in data.items() if value is not None}
    if not data:
        raise HTTPException(status_code=422, detail="Provide at least one field to update")
    assignments = ", ".join(f"`{name}` = %s" for name in data)
    keys = (user_user_id, employee_employee_id, payment_id,)
    sql = f"UPDATE `payment` SET {assignments} WHERE `user_user_id` = %s AND `employee_employee_id` = %s AND `payment_id` = %s"
    return execute(sql, tuple(data.values()) + keys, action="UPDATE",
                   existence=("SELECT 1 FROM `payment` WHERE `user_user_id` = %s AND `employee_employee_id` = %s AND `payment_id` = %s FOR UPDATE", keys))


def delete_payment(
    user_user_id: str,
    employee_employee_id: str,
    payment_id: str,
):
    keys = (user_user_id, employee_employee_id, payment_id,)
    return execute("DELETE FROM `payment` WHERE `user_user_id` = %s AND `employee_employee_id` = %s AND `payment_id` = %s", keys, action="DELETE",
                   existence=("SELECT 1 FROM `payment` WHERE `user_user_id` = %s AND `employee_employee_id` = %s AND `payment_id` = %s FOR UPDATE", keys))
