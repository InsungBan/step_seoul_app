import pymysql
from fastapi import HTTPException

from db.database import db

from services._database import execute


def ensure_pickup_link_columns():
    """Preserve the exact product and purchase for employee-created pickups."""
    conn = None
    try:
        conn = db()
        tick = chr(96)
        columns = {
            "receive_shoe_id": "VARCHAR(20) NULL",
            "receive_purchase_id": "VARCHAR(45) NULL",
        }
        with conn.cursor() as cursor:
            for name, definition in columns.items():
                cursor.execute(
                    f"SHOW COLUMNS FROM {tick}receive{tick} WHERE Field = %s",
                    (name,),
                )
                if cursor.fetchone() is None:
                    cursor.execute(
                        f"ALTER TABLE {tick}receive{tick} ADD COLUMN {tick}{name}{tick} {definition}"
                    )
        conn.commit()
    except pymysql.MySQLError as error:
        if conn is not None:
            conn.rollback()
        raise RuntimeError("Could not prepare pickup link columns") from error
    finally:
        if conn is not None:
            conn.close()

def create_receive(
    store_store_id: str,
    user_user_id: str,
    employee_employee_id: str,
    receive_id: str,
    receive_date: str | None,
    receive_quantity: str | None,
    receive_verification_code: str | None,
    receive_status: str | None,
    receive_verification_status: int | None,
    receive_expdate: str | None,
    receive_payment_id: str | None,
):
    data = {
        "store_store_id": store_store_id,
        "user_user_id": user_user_id,
        "employee_employee_id": employee_employee_id,
        "receive_id": receive_id,
        "receive_date": receive_date,
        "receive_quantity": receive_quantity,
        "receive_verification_code": receive_verification_code,
        "receive_status": receive_status,
        "receive_verification_status": receive_verification_status,
        "receive_expdate": receive_expdate,
        "receive_payment_id": receive_payment_id,
    }
    data = {name: value for name, value in data.items() if value is not None}
    columns = ", ".join(f"`{name}`" for name in data)
    placeholders = ", ".join("%s" for _ in data)
    sql = f"INSERT INTO `receive` ({columns}) VALUES ({placeholders})"
    return execute(sql, tuple(data.values()), action="CREATE")


def read_receive():
    return execute("SELECT * FROM `receive`")


def update_receive(
    store_store_id: str,
    user_user_id: str,
    employee_employee_id: str,
    receive_id: str,
    receive_date: str | None = None,
    receive_quantity: str | None = None,
    receive_verification_code: str | None = None,
    receive_status: str | None = None,
    receive_verification_status: int | None = None,
    receive_expdate: str | None = None,
    receive_payment_id: str | None = None,
):
    data = {
        "receive_date": receive_date,
        "receive_quantity": receive_quantity,
        "receive_verification_code": receive_verification_code,
        "receive_status": receive_status,
        "receive_verification_status": receive_verification_status,
        "receive_expdate": receive_expdate,
        "receive_payment_id": receive_payment_id,
    }
    data = {name: value for name, value in data.items() if value is not None}
    if not data:
        raise HTTPException(status_code=422, detail="Provide at least one field to update")
    assignments = ", ".join(f"`{name}` = %s" for name in data)
    keys = (store_store_id, user_user_id, employee_employee_id, receive_id,)
    sql = f"UPDATE `receive` SET {assignments} WHERE `store_store_id` = %s AND `user_user_id` = %s AND `employee_employee_id` = %s AND `receive_id` = %s"
    return execute(sql, tuple(data.values()) + keys, action="UPDATE",
                   existence=("SELECT 1 FROM `receive` WHERE `store_store_id` = %s AND `user_user_id` = %s AND `employee_employee_id` = %s AND `receive_id` = %s FOR UPDATE", keys))


def delete_receive(
    store_store_id: str,
    user_user_id: str,
    employee_employee_id: str,
    receive_id: str,
):
    keys = (store_store_id, user_user_id, employee_employee_id, receive_id,)
    return execute("DELETE FROM `receive` WHERE `store_store_id` = %s AND `user_user_id` = %s AND `employee_employee_id` = %s AND `receive_id` = %s", keys, action="DELETE",
                   existence=("SELECT 1 FROM `receive` WHERE `store_store_id` = %s AND `user_user_id` = %s AND `employee_employee_id` = %s AND `receive_id` = %s FOR UPDATE", keys))
