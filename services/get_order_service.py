from fastapi import HTTPException

from services._database import execute


def create_get_order(
    shoe_shoe_id: str,
    employee_employee_id: str,
    get_order_id: str,
    get_order_quantity: str | None,
    get_order_status: str | None,
    get_order_date: str | None,
    shoe_manufacturer_manufacturer_id: str,
):
    data = {
        "shoe_shoe_id": shoe_shoe_id,
        "employee_employee_id": employee_employee_id,
        "get_order_id": get_order_id,
        "get_order_quantity": get_order_quantity,
        "get_order_status": get_order_status,
        "get_order_date": get_order_date,
        "shoe_manufacturer_manufacturer_id": shoe_manufacturer_manufacturer_id,
    }
    data = {name: value for name, value in data.items() if value is not None}
    columns = ", ".join(f"`{name}`" for name in data)
    placeholders = ", ".join("%s" for _ in data)
    sql = f"INSERT INTO `get_order` ({columns}) VALUES ({placeholders})"
    return execute(sql, tuple(data.values()), action="CREATE")


def read_get_order():
    return execute("SELECT * FROM `get_order`")


def update_get_order(
    shoe_shoe_id: str,
    employee_employee_id: str,
    get_order_id: str,
    shoe_manufacturer_manufacturer_id: str,
    get_order_quantity: str | None = None,
    get_order_status: str | None = None,
    get_order_date: str | None = None,
):
    data = {
        "get_order_quantity": get_order_quantity,
        "get_order_status": get_order_status,
        "get_order_date": get_order_date,
    }
    data = {name: value for name, value in data.items() if value is not None}
    if not data:
        raise HTTPException(status_code=422, detail="Provide at least one field to update")
    assignments = ", ".join(f"`{name}` = %s" for name in data)
    keys = (shoe_shoe_id, employee_employee_id, get_order_id, shoe_manufacturer_manufacturer_id,)
    sql = f"UPDATE `get_order` SET {assignments} WHERE `shoe_shoe_id` = %s AND `employee_employee_id` = %s AND `get_order_id` = %s AND `shoe_manufacturer_manufacturer_id` = %s"
    return execute(sql, tuple(data.values()) + keys, action="UPDATE",
                   existence=("SELECT 1 FROM `get_order` WHERE `shoe_shoe_id` = %s AND `employee_employee_id` = %s AND `get_order_id` = %s AND `shoe_manufacturer_manufacturer_id` = %s FOR UPDATE", keys))


def delete_get_order(
    shoe_shoe_id: str,
    employee_employee_id: str,
    get_order_id: str,
    shoe_manufacturer_manufacturer_id: str,
):
    keys = (shoe_shoe_id, employee_employee_id, get_order_id, shoe_manufacturer_manufacturer_id,)
    return execute("DELETE FROM `get_order` WHERE `shoe_shoe_id` = %s AND `employee_employee_id` = %s AND `get_order_id` = %s AND `shoe_manufacturer_manufacturer_id` = %s", keys, action="DELETE",
                   existence=("SELECT 1 FROM `get_order` WHERE `shoe_shoe_id` = %s AND `employee_employee_id` = %s AND `get_order_id` = %s AND `shoe_manufacturer_manufacturer_id` = %s FOR UPDATE", keys))
