"""Read-only HQ snapshot; no UI fixtures or credentials are returned."""
import logging

import pymysql
from datetime import date
from fastapi import APIRouter, HTTPException
from services.hq_service import REPORTS, build_reports
from db.database import db

router = APIRouter(prefix="/hq", tags=["hq"])
logger = logging.getLogger(__name__)
COLUMNS = {'shoe': ['shoe_id', 'brand_name', 'shoe_category', 'shoe_image_url', 'shoe_price', 'standard_stock', 'stock_quantity'], 'purchase': ['shoe_shoe_id', 'user_user_id', 'purchase_id', 'sale_price', 'payment_id', 'quantity'], 'shipment': ['shoe_shoe_id', 'employee_employee_id', 'shipment_id', 'delivery_status', 'delivery_quantity', 'store_store_id'], 'receive': ['store_store_id', 'user_user_id', 'employee_employee_id', 'receive_id', 'receive_date', 'receive_quantity', 'receive_status', 'receive_verification_status', 'receive_expdate', 'receive_payment_id'], 'return_record': ['shoe_shoe_id', 'employee_employee_id', 'return_id', 'return_date'], 'approval': ['approval_id', 'approval_name', 'approval_content'], 'approval_process': ['employee_employee_id', 'approval_approval_id', 'approval_process_id', 'approval_date', 'director_approval', 'team_leader_approval', 'approval_status', 'processed_at'], 'purchase_order': ['shoe_manufacturer_manufacturer_id', 'approval_approval_id', 'order_date', 'get_amount', 'order_id', 'order_quantity', 'shoe_shoe_id'], 'get_order': ['shoe_shoe_id', 'employee_employee_id', 'get_order_id', 'get_order_quantity', 'get_order_date', 'shoe_manufacturer_manufacturer_id'], 'payment': ['user_user_id', 'employee_employee_id', 'payment_id', 'payment_date', 'payment_amount', 'payment_status', 'discount_flag'], 'user': ['user_id', 'user_name', 'user_phone', 'user_email', 'join_date'], 'employee': ['employee_id', 'employee_position', 'employee_name', 'employee_department'], 'store': ['store_id', 'latitude', 'longitude', 'district_name', 'agency_name', 'phone'], 'shoe_manufacturer': ['manufacturer_id', 'manufacturer_name']}
COLUMNS.update({'manufacturing': ['shoe_shoe_id', 'shoe_manufacturer_manufacturer_id', 'manufacturing_id', 'manufacturing_date'], 'recall': ['store_store_id', 'user_user_id', 'recall_id', 'recall_date', 'recall_quantity', 'employee_employee_id'], 'refund': ['user_user_id', 'employee_employee_id', 'refund_id', 'refund_amount', 'refund_quantity', 'refund_reason'], 'authentication': ['user_user_id', 'employee_employee_id', 'authentication_id', 'authentication_date'], 'cart': ['user_user_id', 'shoe_shoe_id', 'cart_id', 'added_at']})

OPTIONAL_COLUMNS = {
    'shipment': ['purchase_purchase_id'],
    'approval': ['requested_amount', 'approval_date'],
    'purchase': ['store_store_id'],
    'purchase_order': ['is_auto', 'created_at'],
    'return_record': ['purchase_purchase_id', 'return_quantity', 'refund_refund_id'],
    'stock_movement': ['movement_id', 'shoe_shoe_id', 'changed_at', 'quantity_delta', 'stock_after', 'reason'],
}


def read_snapshot():
    conn = None
    try:
        conn = db()
        conn.begin()
        result = {}
        with conn.cursor(pymysql.cursors.DictCursor) as cursor:
            cursor.execute("SELECT TABLE_NAME, COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE()")
            schema = {}
            for item in cursor.fetchall():
                schema.setdefault(item['TABLE_NAME'], []).append(item['COLUMN_NAME'])
            result['_hq_schema'] = [schema]
            selected_tables = dict(COLUMNS)
            if 'stock_movement' in schema:
                movement_columns = [c for c in OPTIONAL_COLUMNS['stock_movement'] if c in schema['stock_movement']]
                if movement_columns:
                    selected_tables['stock_movement'] = movement_columns
            for table, base_columns in selected_tables.items():
                columns = base_columns + [c for c in OPTIONAL_COLUMNS.get(table, []) if c in schema.get(table, []) and c not in base_columns]
                selected = ", ".join(f"`{column}`" for column in columns)
                cursor.execute(f"SELECT {selected} FROM `{table}`")
                result[table] = list(cursor.fetchall())
        conn.rollback()  # Read-only snapshot.
        return {"result": result}
    except pymysql.MySQLError:
        logger.exception("HQ snapshot failed")
        raise HTTPException(status_code=503, detail="Database unavailable") from None
    finally:
        if conn is not None:
            conn.close()


@router.get("/snapshot")
def snapshot(start: date | None = None, end: date | None = None):
    if start is not None and end is not None and start > end:
        raise HTTPException(status_code=422, detail="start must not exceed end")
    result = read_snapshot()["result"]
    result["hq_reports"] = [build_reports(result, start, end)]
    return {"result": result}


def report_endpoint(name):
    def select(start: date | None = None, end: date | None = None):
        if start is not None and end is not None and start > end:
            raise HTTPException(status_code=422, detail="start must not exceed end")
        return build_reports(read_snapshot()["result"], start, end)[name]
    select.__name__ = "select_" + name.replace("-", "_")
    return select


for report_name in REPORTS:
    router.add_api_route(f"/{report_name}/select", report_endpoint(report_name), methods=["GET"])
