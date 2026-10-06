from fastapi import HTTPException

from services._database import execute
from db.database import db
import pymysql
import logging


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


def update_shipment(
    shoe_shoe_id: str,
    employee_employee_id: str,
    shipment_id: str,
    store_store_id: str,
    delivery_status: str | None = None,
    delivery_quantity: int | None = None,
    purchase_purchase_id: str | None = None,
):
    data = {
        "delivery_status": delivery_status,
        "delivery_quantity": delivery_quantity,
        "purchase_purchase_id": purchase_purchase_id,
    }
    data = {name: value for name, value in data.items() if value is not None}
    if not data:
        raise HTTPException(status_code=422, detail="Provide at least one field to update")
    assignments = ", ".join(f"`{name}` = %s" for name in data)
    keys = (shoe_shoe_id, employee_employee_id, shipment_id, store_store_id,)
    sql = f"UPDATE `shipment` SET {assignments} WHERE `shoe_shoe_id` = %s AND `employee_employee_id` = %s AND `shipment_id` = %s AND `store_store_id` = %s"
    return execute(sql, tuple(data.values()) + keys, action="UPDATE",
                   validation=order_validation(purchase_purchase_id, shoe_shoe_id),
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
