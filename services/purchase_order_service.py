from fastapi import HTTPException

from services._database import execute


def create_purchase_order(
    shoe_manufacturer_manufacturer_id: str,
    approval_approval_id: str,
    order_date: str | None,
    get_amount: str | None,
    order_id: str,
    order_quantity: str | None,
    shoe_shoe_id: str,
):
    data = {
        "shoe_manufacturer_manufacturer_id": shoe_manufacturer_manufacturer_id,
        "approval_approval_id": approval_approval_id,
        "order_date": order_date,
        "get_amount": get_amount,
        "order_id": order_id,
        "order_quantity": order_quantity,
        "shoe_shoe_id": shoe_shoe_id,
    }
    data = {name: value for name, value in data.items() if value is not None}
    columns = ", ".join(f"`{name}`" for name in data)
    placeholders = ", ".join("%s" for _ in data)
    sql = f"INSERT INTO `purchase_order` ({columns}) VALUES ({placeholders})"
    return execute(sql, tuple(data.values()), action="CREATE")


def read_purchase_order():
    return execute("SELECT * FROM `purchase_order`")


def update_purchase_order(
    shoe_manufacturer_manufacturer_id: str,
    approval_approval_id: str,
    order_id: str,
    shoe_shoe_id: str,
    order_date: str | None = None,
    get_amount: str | None = None,
    order_quantity: str | None = None,
):
    data = {
        "order_date": order_date,
        "get_amount": get_amount,
        "order_quantity": order_quantity,
    }
    data = {name: value for name, value in data.items() if value is not None}
    if not data:
        raise HTTPException(status_code=422, detail="Provide at least one field to update")
    assignments = ", ".join(f"`{name}` = %s" for name in data)
    keys = (shoe_manufacturer_manufacturer_id, approval_approval_id, order_id, shoe_shoe_id,)
    sql = f"UPDATE `purchase_order` SET {assignments} WHERE `shoe_manufacturer_manufacturer_id` = %s AND `approval_approval_id` = %s AND `order_id` = %s AND `shoe_shoe_id` = %s"
    return execute(sql, tuple(data.values()) + keys, action="UPDATE",
                   existence=("SELECT 1 FROM `purchase_order` WHERE `shoe_manufacturer_manufacturer_id` = %s AND `approval_approval_id` = %s AND `order_id` = %s AND `shoe_shoe_id` = %s FOR UPDATE", keys))


def delete_purchase_order(
    shoe_manufacturer_manufacturer_id: str,
    approval_approval_id: str,
    order_id: str,
    shoe_shoe_id: str,
):
    keys = (shoe_manufacturer_manufacturer_id, approval_approval_id, order_id, shoe_shoe_id,)
    return execute("DELETE FROM `purchase_order` WHERE `shoe_manufacturer_manufacturer_id` = %s AND `approval_approval_id` = %s AND `order_id` = %s AND `shoe_shoe_id` = %s", keys, action="DELETE",
                   existence=("SELECT 1 FROM `purchase_order` WHERE `shoe_manufacturer_manufacturer_id` = %s AND `approval_approval_id` = %s AND `order_id` = %s AND `shoe_shoe_id` = %s FOR UPDATE", keys))
