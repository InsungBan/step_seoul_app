from fastapi import HTTPException

from services._database import execute


def create_shipment(
    shoe_shoe_id: str,
    employee_employee_id: str,
    shipment_id: str,
    delivery_status: str | None,
    delivery_quantity: int | None,
    store_store_id: str,
):
    data = {
        "shoe_shoe_id": shoe_shoe_id,
        "employee_employee_id": employee_employee_id,
        "shipment_id": shipment_id,
        "delivery_status": delivery_status,
        "delivery_quantity": delivery_quantity,
        "store_store_id": store_store_id,
    }
    data = {name: value for name, value in data.items() if value is not None}
    columns = ", ".join(f"`{name}`" for name in data)
    placeholders = ", ".join("%s" for _ in data)
    sql = f"INSERT INTO `shipment` ({columns}) VALUES ({placeholders})"
    return execute(sql, tuple(data.values()), action="CREATE")


def read_shipment():
    return execute("SELECT * FROM `shipment`")


def update_shipment(
    shoe_shoe_id: str,
    employee_employee_id: str,
    shipment_id: str,
    store_store_id: str,
    delivery_status: str | None = None,
    delivery_quantity: int | None = None,
):
    data = {
        "delivery_status": delivery_status,
        "delivery_quantity": delivery_quantity,
    }
    data = {name: value for name, value in data.items() if value is not None}
    if not data:
        raise HTTPException(status_code=422, detail="Provide at least one field to update")
    assignments = ", ".join(f"`{name}` = %s" for name in data)
    keys = (shoe_shoe_id, employee_employee_id, shipment_id, store_store_id,)
    sql = f"UPDATE `shipment` SET {assignments} WHERE `shoe_shoe_id` = %s AND `employee_employee_id` = %s AND `shipment_id` = %s AND `store_store_id` = %s"
    return execute(sql, tuple(data.values()) + keys, action="UPDATE",
                   existence=("SELECT 1 FROM `shipment` WHERE `shoe_shoe_id` = %s AND `employee_employee_id` = %s AND `shipment_id` = %s AND `store_store_id` = %s FOR UPDATE", keys))


def delete_shipment(
    shoe_shoe_id: str,
    employee_employee_id: str,
    shipment_id: str,
    store_store_id: str,
):
    keys = (shoe_shoe_id, employee_employee_id, shipment_id, store_store_id,)
    return execute("DELETE FROM `shipment` WHERE `shoe_shoe_id` = %s AND `employee_employee_id` = %s AND `shipment_id` = %s AND `store_store_id` = %s", keys, action="DELETE",
                   existence=("SELECT 1 FROM `shipment` WHERE `shoe_shoe_id` = %s AND `employee_employee_id` = %s AND `shipment_id` = %s AND `store_store_id` = %s FOR UPDATE", keys))
