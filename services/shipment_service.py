import pymysql
from datetime import datetime
from fastapi import HTTPException

from db.database import db
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


def read_shipment_in_transit():
    """Return transit shipments with the matching customer purchase data."""
    return execute(
        """
        SELECT
            s.*,
            p.user_user_id AS pickup_user_id,
            p.payment_id AS pickup_payment_id,
            p.purchase_id AS pickup_purchase_id,
            p.quantity AS pickup_purchase_quantity
        FROM shipment AS s
        LEFT JOIN purchase AS p
          ON p.shoe_shoe_id = s.shoe_shoe_id
         AND (
              p.purchase_id = s.shipment_id
              OR p.payment_id = s.shipment_id
              OR SUBSTRING_INDEX(p.purchase_id, '-', -1) =
                 SUBSTRING_INDEX(SUBSTRING_INDEX(s.shipment_id, '-', -2), '-', 1)
         )
        WHERE LOWER(REPLACE(REPLACE(COALESCE(s.delivery_status, ''), ' ', ''), '_', ''))
          IN ('배송중', '매장으로배송중', '물류센터이동중', 'intransit', 'transit')
        ORDER BY s.shipment_id
        """
    )
def read_shipment_for_shoe(shoe_shoe_id: str):
    return execute(
        "SELECT * FROM `shipment` WHERE `shoe_shoe_id` = %s",
        (shoe_shoe_id,),
    )


def update_shipment(
    shoe_shoe_id: str,
    employee_employee_id: str,
    shipment_id: str,
    store_store_id: str,
    delivery_status: str | None = None,
    delivery_quantity: int | None = None,
    pickup_user_id: str | None = None,
    pickup_payment_id: str | None = None,
    receive_id: str | None = None,
    receive_quantity: int | None = None,
    pickup_purchase_id: str | None = None,
):
    pickup_values = (
        pickup_user_id,
        pickup_payment_id,
        receive_id,
        receive_quantity,
        pickup_purchase_id,
    )
    if any(value is not None for value in pickup_values):
        if not all(value is not None and str(value).strip() for value in pickup_values):
            raise HTTPException(status_code=422, detail="Customer purchase data is required to create a pickup")
        if receive_quantity is None or receive_quantity < 1:
            raise HTTPException(status_code=422, detail="Receive quantity must be at least one")
        return _update_shipment_and_create_pickup(
            shoe_shoe_id,
            employee_employee_id,
            shipment_id,
            store_store_id,
            delivery_status or "배송완료",
            delivery_quantity,
            pickup_user_id,
            pickup_payment_id,
            receive_id,
            receive_quantity,
            pickup_purchase_id,
        )

    data = {
        "delivery_status": delivery_status,
        "delivery_quantity": delivery_quantity,
    }
    data = {name: value for name, value in data.items() if value is not None}
    if not data:
        raise HTTPException(status_code=422, detail="Provide at least one field to update")
    assignments = ", ".join(f"{chr(96)}{name}{chr(96)} = %s" for name in data)
    keys = (shoe_shoe_id, employee_employee_id, shipment_id, store_store_id)
    tick = chr(96)
    sql = "UPDATE " + tick + "shipment" + tick + " SET " + assignments + " WHERE " + tick + "shoe_shoe_id" + tick + " = %s AND " + tick + "employee_employee_id" + tick + " = %s AND " + tick + "shipment_id" + tick + " = %s AND " + tick + "store_store_id" + tick + " = %s"
    return execute(
        sql,
        tuple(data.values()) + keys,
        action="UPDATE",
        existence=(
            "SELECT 1 FROM " + tick + "shipment" + tick + " WHERE " + tick + "shoe_shoe_id" + tick + " = %s AND " + tick + "employee_employee_id" + tick + " = %s AND " + tick + "shipment_id" + tick + " = %s AND " + tick + "store_store_id" + tick + " = %s FOR UPDATE",
            keys,
        ),
    )

def _update_shipment_and_create_pickup(
    shoe_id: str,
    employee_id: str,
    shipment_id: str,
    store_id: str,
    delivery_status: str,
    delivery_quantity: int | None,
    user_id: str,
    payment_id: str,
    receive_id: str,
    receive_quantity: int,
    pickup_purchase_id: str,
):
    conn = None
    try:
        conn = db()
        tick = chr(96)
        with conn.cursor(pymysql.cursors.DictCursor) as cursor:
            cursor.execute(
                "SELECT 1 FROM " + tick + "shipment" + tick + " WHERE " + tick + "shoe_shoe_id" + tick + " = %s AND " + tick + "employee_employee_id" + tick + " = %s AND " + tick + "shipment_id" + tick + " = %s AND " + tick + "store_store_id" + tick + " = %s FOR UPDATE",
                (shoe_id, employee_id, shipment_id, store_id),
            )
            if cursor.fetchone() is None:
                raise HTTPException(status_code=404, detail="Shipment not found")

            update_values = {"delivery_status": delivery_status}
            if delivery_quantity is not None:
                update_values["delivery_quantity"] = delivery_quantity
            assignments = ", ".join(
                tick + name + tick + " = %s" for name in update_values
            )
            cursor.execute(
                "UPDATE " + tick + "shipment" + tick + " SET " + assignments +
                " WHERE " + tick + "shoe_shoe_id" + tick + " = %s AND " +
                tick + "employee_employee_id" + tick + " = %s AND " +
                tick + "shipment_id" + tick + " = %s AND " +
                tick + "store_store_id" + tick + " = %s",
                tuple(update_values.values()) + (shoe_id, employee_id, shipment_id, store_id),
            )

            receive_data = {
                "store_store_id": store_id,
                "user_user_id": user_id,
                "employee_employee_id": employee_id,
                "receive_id": receive_id,
                "receive_date": datetime.now(),
                "receive_quantity": str(receive_quantity),
                "receive_status": "WAITING",
                "receive_verification_status": 0,
                "receive_payment_id": payment_id,
                "receive_shoe_id": shoe_id,
                "receive_purchase_id": pickup_purchase_id,
            }
            columns = ", ".join(tick + name + tick for name in receive_data)
            placeholders = ", ".join(["%s"] * len(receive_data))
            cursor.execute(
                "INSERT INTO " + tick + "receive" + tick + " (" + columns + ") VALUES (" + placeholders + ")",
                tuple(receive_data.values()),
            )
        conn.commit()
        return {"result": "UPDATE OK; PICKUP CREATED"}
    except HTTPException:
        if conn is not None:
            conn.rollback()
        raise
    except pymysql.MySQLError:
        if conn is not None:
            conn.rollback()
        raise HTTPException(status_code=500, detail="Could not complete shipment inbound") from None
    finally:
        if conn is not None:
            conn.close()
def delete_shipment(
    shoe_shoe_id: str,
    employee_employee_id: str,
    shipment_id: str,
    store_store_id: str,
):
    keys = (shoe_shoe_id, employee_employee_id, shipment_id, store_store_id,)
    return execute("DELETE FROM `shipment` WHERE `shoe_shoe_id` = %s AND `employee_employee_id` = %s AND `shipment_id` = %s AND `store_store_id` = %s", keys, action="DELETE",
                   existence=("SELECT 1 FROM `shipment` WHERE `shoe_shoe_id` = %s AND `employee_employee_id` = %s AND `shipment_id` = %s AND `store_store_id` = %s FOR UPDATE", keys))
