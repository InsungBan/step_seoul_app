import logging
import re
from datetime import datetime

import pymysql
from fastapi import HTTPException

from db.database import db
from services._database import execute


def dispatch_shipments(shipments):
    fields = ('shoe_shoe_id', 'employee_employee_id', 'shipment_id', 'store_store_id')
    keys = sorted({tuple(row[field] for field in fields) for row in shipments})
    where = ' AND '.join(f'`{field}` = %s' for field in fields)
    conn = None
    try:
        conn = db()
        conn.begin()
        with conn.cursor() as cursor:
            for key in keys:
                cursor.execute(f'SELECT 1 FROM shipment WHERE {where} FOR UPDATE', key)
                if cursor.fetchone() is None:
                    raise HTTPException(status_code=404, detail='Selected shipment no longer exists')
            for key in keys:
                cursor.execute(f'UPDATE shipment SET delivery_status = %s WHERE {where}', ('배송 중',) + key)
        conn.commit()
        return {'result': 'UPDATE OK', 'updated_count': len(keys)}
    except HTTPException:
        if conn is not None:
            conn.rollback()
        raise
    except pymysql.MySQLError:
        if conn is not None:
            conn.rollback()
        logging.getLogger(__name__).exception('Shipment dispatch failed')
        raise HTTPException(status_code=500, detail='Shipment dispatch failed') from None
    finally:
        if conn is not None:
            conn.close()


def order_validation(order_id, shoe_id):
    return None if order_id is None else (
        'SELECT purchase_id FROM purchase WHERE purchase_id = %s AND shoe_shoe_id = %s FOR UPDATE',
        (order_id, shoe_id),
    )


def create_shipment(
    shoe_shoe_id: str,
    employee_employee_id: str,
    shipment_id: str,
    delivery_status: str | None,
    delivery_quantity: int | None,
    store_store_id: str,
    purchase_purchase_id: str | None = None,
):
    data = {
        "shoe_shoe_id": shoe_shoe_id,
        "employee_employee_id": employee_employee_id,
        "shipment_id": shipment_id,
        "delivery_status": delivery_status,
        "delivery_quantity": delivery_quantity,
        "store_store_id": store_store_id,
        "purchase_purchase_id": purchase_purchase_id,
    }
    data = {name: value for name, value in data.items() if value is not None}
    columns = ", ".join(f"`{name}`" for name in data)
    placeholders = ", ".join("%s" for _ in data)
    sql = f"INSERT INTO `shipment` ({columns}) VALUES ({placeholders})"
    return execute(sql, tuple(data.values()), action="CREATE", validation=order_validation(purchase_purchase_id, shoe_shoe_id))


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
          ON p.purchase_id = s.purchase_purchase_id
         AND p.shoe_shoe_id = s.shoe_shoe_id
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
def ensure_shipment_purchase_links():
    """Ensure direct order links exist and backfill unambiguous legacy rows."""
    conn = db()
    try:
        with conn.cursor(pymysql.cursors.DictCursor) as cursor:
            cursor.execute(
                "SELECT 1 FROM information_schema.COLUMNS "
                "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'shipment' "
                "AND COLUMN_NAME = 'purchase_purchase_id'"
            )
            if cursor.fetchone() is None:
                cursor.execute(
                    "ALTER TABLE `shipment` ADD COLUMN `purchase_purchase_id` VARCHAR(45) NULL"
                )
            cursor.execute(
                "SELECT `shoe_shoe_id`, `employee_employee_id`, `shipment_id`, `store_store_id` "
                "FROM `shipment` WHERE `purchase_purchase_id` IS NULL "
                "OR TRIM(`purchase_purchase_id`) = ''"
            )
            for shipment in cursor.fetchall():
                match = re.match(r"^SHP-([^-]+)-[0-9]+$", shipment["shipment_id"] or "")
                if not match:
                    continue
                suffix = match.group(1)
                cursor.execute(
                    "SELECT `purchase_id` FROM `purchase` WHERE `shoe_shoe_id` = %s "
                    "AND `purchase_id` LIKE %s",
                    (shipment["shoe_shoe_id"], f"%-{suffix}"),
                )
                purchases = cursor.fetchall()
                if len(purchases) != 1:
                    continue
                cursor.execute(
                    "UPDATE `shipment` SET `purchase_purchase_id` = %s "
                    "WHERE `shoe_shoe_id` = %s AND `employee_employee_id` = %s "
                    "AND `shipment_id` = %s AND `store_store_id` = %s",
                    (
                        purchases[0]["purchase_id"],
                        shipment["shoe_shoe_id"],
                        shipment["employee_employee_id"],
                        shipment["shipment_id"],
                        shipment["store_store_id"],
                    ),
                )
        conn.commit()
    except pymysql.MySQLError:
        conn.rollback()
        raise
    finally:
        conn.close()
