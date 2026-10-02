from datetime import datetime
from uuid import uuid4

import pymysql
from fastapi import HTTPException

from db.database import db


def create_refund_request(
    user_id: str,
    order_id: str,
    shoe_id: str,
    quantity: int,
    reason: str,
    detail_reason: str | None,
):
    """Creates a customer refund request after confirming order ownership."""
    conn = None
    try:
        conn = db()
        with conn.cursor(pymysql.cursors.DictCursor) as cursor:
            cursor.execute(
                """
                SELECT * FROM `purchase`
                WHERE `user_user_id` = %s AND `purchase_id` = %s
                  AND `shoe_shoe_id` = %s
                FOR UPDATE
                """,
                (user_id, order_id, shoe_id),
            )
            purchase = cursor.fetchone()
            if purchase is None:
                raise HTTPException(status_code=404, detail="Ordered item not found")
            purchased_quantity = int(purchase.get("quantity") or 1)
            if quantity < 1 or quantity > purchased_quantity:
                raise HTTPException(status_code=422, detail="Invalid refund quantity")

            cursor.execute(
                "SELECT `employee_id` FROM `employee` ORDER BY `employee_id` LIMIT 1"
            )
            employee = cursor.fetchone()
            if employee is None:
                raise HTTPException(status_code=422, detail="A store employee is required")

            cursor.execute(
                "SELECT `sale_price` FROM `purchase` WHERE `user_user_id` = %s AND `purchase_id` = %s AND `shoe_shoe_id` = %s LIMIT 1",
                (user_id, order_id, shoe_id),
            )
            sale = cursor.fetchone() or {}
            unit_price = int("".join(filter(str.isdigit, str(sale.get("sale_price") or 0))) or 0)
            refund_id = f"RFD-{datetime.now():%Y%m%d}-{uuid4().hex[:8].upper()}"
            reason_text = reason.strip()
            if detail_reason and detail_reason.strip():
                reason_text = f"{reason_text}: {detail_reason.strip()}"
            cursor.execute(
                """
                INSERT INTO `refund`
                  (`user_user_id`, `employee_employee_id`, `refund_id`,
                   `refund_amount`, `refund_quantity`, `refund_reason`, `refund_cardnumber`)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                """,
                (
                    user_id,
                    employee["employee_id"],
                    refund_id,
                    str(unit_price * quantity),
                    str(quantity),
                    reason_text[:45],
                    None,
                ),
            )
        conn.commit()
        return {
            "result": {
                "refund_id": refund_id,
                "order_id": order_id,
                "shoe_id": shoe_id,
                "quantity": quantity,
                "amount": unit_price * quantity,
                "status": "Requested",
            }
        }
    except HTTPException:
        if conn is not None:
            conn.rollback()
        raise
    except (ValueError, TypeError):
        if conn is not None:
            conn.rollback()
        raise HTTPException(status_code=422, detail="Invalid refund request") from None
    except pymysql.MySQLError:
        if conn is not None:
            conn.rollback()
        raise HTTPException(status_code=500, detail="Refund request could not be created") from None
    finally:
        if conn is not None:
            conn.close()
