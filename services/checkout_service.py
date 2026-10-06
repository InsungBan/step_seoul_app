from datetime import datetime
from uuid import uuid4

import pymysql
from fastapi import HTTPException

from db.database import db


def _display_shoe_name(shoe: dict, shoe_id: str) -> str:
    shoe_name = shoe.get("shoe_name")
    if shoe_name is not None and shoe_name.strip():
        return shoe_name
    return shoe.get("brand_name") or shoe_id


def complete_checkout(
    user_id: str,
    store_id: str,
    items: list[dict],
    payment_method: str,
    clear_cart: bool,
):
    if not items:
        raise HTTPException(status_code=422, detail="At least one order item is required")

    conn = None
    try:
        conn = db()
        with conn.cursor(pymysql.cursors.DictCursor) as cursor:
            cursor.execute("SELECT 1 FROM `user` WHERE `user_id` = %s FOR UPDATE", (user_id,))
            if cursor.fetchone() is None:
                raise HTTPException(status_code=404, detail="User not found")
            cursor.execute("SELECT * FROM `store` WHERE `store_id` = %s FOR UPDATE", (store_id,))
            store = cursor.fetchone()
            if store is None:
                raise HTTPException(status_code=404, detail="Store not found")
            cursor.execute("SELECT `employee_id` FROM `employee` ORDER BY `employee_id` LIMIT 1")
            employee = cursor.fetchone()
            if employee is None:
                raise HTTPException(status_code=422, detail="A store employee is required before checkout")

            validated_items = []
            total = 0
            for item in items:
                shoe_id = str(item.get("shoe_id", "")).strip()
                quantity = int(item.get("quantity", 0))
                if not shoe_id or quantity < 1:
                    raise HTTPException(status_code=422, detail="Invalid order item")
                cursor.execute("SELECT * FROM `shoe` WHERE `shoe_id` = %s FOR UPDATE", (shoe_id,))
                shoe = cursor.fetchone()
                if shoe is None:
                    raise HTTPException(status_code=404, detail=f"Shoe not found: {shoe_id}")
                stock = int(shoe.get("stock_quantity") or 0)
                if stock < quantity:
                    raise HTTPException(status_code=409, detail=f"Insufficient stock: {shoe_id}")
                price = int("".join(filter(str.isdigit, str(shoe.get("shoe_price") or "0"))) or 0)
                total += price * quantity
                validated_items.append((shoe, quantity, price))

            now = datetime.now()
            suffix = uuid4().hex[:8].upper()
            order_id = f"ORD-{now:%Y%m%d}-{suffix}"
            payment_id = f"PAY-{now:%Y%m%d}-{suffix}"
            employee_id = employee["employee_id"]
            cursor.execute(
                """
                INSERT INTO `payment`
                  (`user_user_id`, `employee_employee_id`, `payment_id`,
                   `payment_date`, `payment_amount`, `payment_status`, `discount_flag`)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                """,
                (user_id, employee_id, payment_id, now.isoformat(timespec="seconds"), total, 1, payment_method),
            )
            response_items = []
            for index, (shoe, quantity, price) in enumerate(validated_items, start=1):
                shoe_id = shoe["shoe_id"]
                cursor.execute(
                    """
                    INSERT INTO `purchase`
                      (`shoe_shoe_id`, `user_user_id`, `purchase_id`, `sale_price`,
                       `payment_id`, `quantity`, `store_store_id`)
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                    """,
                    (shoe_id, user_id, order_id, str(price), payment_id, str(quantity), store_id),
                )
                shipment_id = f"SHP-{suffix}-{index}"
                cursor.execute(
                    """
                    INSERT INTO `shipment`
                      (`shoe_shoe_id`, `employee_employee_id`, `shipment_id`,
                       `delivery_status`, `delivery_quantity`, `store_store_id`)
                    VALUES (%s, %s, %s, %s, %s, %s)
                    """,
                    (shoe_id, employee_id, shipment_id, "Preparing pickup", quantity, store_id),
                )
                cursor.execute(
                    "UPDATE `shoe` SET `stock_quantity` = `stock_quantity` - %s WHERE `shoe_id` = %s",
                    (quantity, shoe_id),
                )
                response_items.append({
                    "shoe_id": shoe_id,
                    "shoe_name": _display_shoe_name(shoe, shoe_id),
                    "quantity": quantity,
                    "price": price,
                })
            if clear_cart:
                cursor.execute("DELETE FROM `cart` WHERE `user_user_id` = %s", (user_id,))
        conn.commit()
        return {
            "result": {
                "order_id": order_id,
                "payment_id": payment_id,
                "paid_at": now.isoformat(timespec="seconds"),
                "total": total,
                "store": {
                    "store_id": store["store_id"],
                    "name": store.get("agency_name") or store["store_id"],
                    "district": store.get("district_name") or "",
                },
                "items": response_items,
            }
        }
    except HTTPException:
        if conn is not None:
            conn.rollback()
        raise
    except (ValueError, TypeError):
        if conn is not None:
            conn.rollback()
        raise HTTPException(status_code=422, detail="Invalid checkout data") from None
    except pymysql.MySQLError:
        if conn is not None:
            conn.rollback()
        raise HTTPException(status_code=500, detail="Checkout could not be completed") from None
    finally:
        if conn is not None:
            conn.close()


def read_order_detail(user_id: str, order_id: str):
    conn = None
    try:
        conn = db()
        with conn.cursor(pymysql.cursors.DictCursor) as cursor:
            cursor.execute(
                "SELECT * FROM `purchase` WHERE `user_user_id` = %s AND `purchase_id` = %s",
                (user_id, order_id),
            )
            purchases = cursor.fetchall()
            if not purchases:
                raise HTTPException(status_code=404, detail="Order not found")
            items = []
            store = None
            status = "Preparing pickup"
            payment = None
            for purchase in purchases:
                cursor.execute("SELECT * FROM `shoe` WHERE `shoe_id` = %s", (purchase["shoe_shoe_id"],))
                shoe = cursor.fetchone() or {}
                cursor.execute(
                    "SELECT * FROM `shipment` WHERE `shoe_shoe_id` = %s ORDER BY `shipment_id` DESC LIMIT 1",
                    (purchase["shoe_shoe_id"],),
                )
                shipment = cursor.fetchone()
                if shipment:
                    status = shipment.get("delivery_status") or status
                    cursor.execute("SELECT * FROM `store` WHERE `store_id` = %s", (shipment["store_store_id"],))
                    store = cursor.fetchone() or store
                if payment is None and purchase.get("payment_id"):
                    cursor.execute(
                        "SELECT * FROM `payment` WHERE `user_user_id` = %s AND `payment_id` = %s LIMIT 1",
                        (user_id, purchase["payment_id"]),
                    )
                    payment = cursor.fetchone()
                items.append({
                    "shoe_id": purchase["shoe_shoe_id"],
                    "name": _display_shoe_name(shoe, purchase["shoe_shoe_id"]),
                    "price": int("".join(filter(str.isdigit, str(purchase.get("sale_price") or shoe.get("shoe_price") or 0))) or 0),
                    "quantity": int(purchase.get("quantity") or 1),
                    "category": shoe.get("shoe_category") or "",
                    "shoe_img_url": shoe.get("shoe_img_url"),
                    "shoe_image_url": shoe.get("shoe_image_url"),
                    "stock": int(shoe.get("stock_quantity") or 0),
                })
        total = sum(item["price"] * item["quantity"] for item in items)
        return {"result": {"order_id": order_id, "status": status, "items": items, "total": total, "store": store, "payment": payment}}
    except HTTPException:
        raise
    except pymysql.MySQLError:
        raise HTTPException(status_code=500, detail="Could not load order detail") from None
    finally:
        if conn is not None:
            conn.close()
