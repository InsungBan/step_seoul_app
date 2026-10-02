import pymysql
from fastapi import HTTPException

from services._database import execute
from db.database import db


def ensure_shoe_category_column():
    """Add optional storefront columns once for older STEP SEOUL databases."""
    conn = None
    try:
        conn = db()
        with conn.cursor() as curs:
            curs.execute("SHOW COLUMNS FROM `shoe` LIKE 'shoe_category'")
            if curs.fetchone() is None:
                curs.execute(
                    "ALTER TABLE `shoe` ADD COLUMN `shoe_category` VARCHAR(45) NULL "
                    "AFTER `brand_name`"
                )
            curs.execute("SHOW COLUMNS FROM `shoe` LIKE 'shoe_image_url'")
            if curs.fetchone() is None:
                curs.execute(
                    "ALTER TABLE `shoe` ADD COLUMN `shoe_image_url` TEXT NULL "
                    "AFTER `shoe_category`"
                )
        conn.commit()
    except pymysql.MySQLError as error:
        if conn is not None:
            conn.rollback()
        raise RuntimeError('Could not prepare the shoe category column') from error
    finally:
        if conn is not None:
            conn.close()


def create_shoe(
    shoe_id: str,
    brand_name: str | None,
    shoe_category: str | None,
    shoe_image_url: str | None,
    shoe_price: str | None,
    standard_stock: int | None,
    stock_quantity: int | None,
):
    data = {
        "shoe_id": shoe_id,
        "brand_name": brand_name,
        "shoe_category": shoe_category,
        "shoe_image_url": shoe_image_url,
        "shoe_price": shoe_price,
        "standard_stock": standard_stock,
        "stock_quantity": stock_quantity,
    }
    data = {name: value for name, value in data.items() if value is not None}
    columns = ", ".join(f"`{name}`" for name in data)
    placeholders = ", ".join("%s" for _ in data)
    sql = f"INSERT INTO `shoe` ({columns}) VALUES ({placeholders})"
    return execute(sql, tuple(data.values()), action="CREATE")


def read_shoe():
    return execute("SELECT * FROM `shoe`")


def search_shoe(query: str | None = None, category: str | None = None):
    clauses = []
    params = []
    if query:
        keyword = f"%{query.strip()}%"
        clauses.append("(`shoe_id` LIKE %s OR `brand_name` LIKE %s)")
        params.extend((keyword, keyword))
    if category:
        clauses.append("`shoe_category` = %s")
        params.append(category.strip())

    sql = "SELECT * FROM `shoe`"
    if clauses:
        sql += " WHERE " + " AND ".join(clauses)
    sql += " ORDER BY `shoe_id`"
    return execute(sql, tuple(params))


def update_shoe(
    shoe_id: str,
    brand_name: str | None = None,
    shoe_category: str | None = None,
    shoe_image_url: str | None = None,
    shoe_price: str | None = None,
    standard_stock: int | None = None,
    stock_quantity: int | None = None,
):
    data = {
        "brand_name": brand_name,
        "shoe_category": shoe_category,
        "shoe_image_url": shoe_image_url,
        "shoe_price": shoe_price,
        "standard_stock": standard_stock,
        "stock_quantity": stock_quantity,
    }
    data = {name: value for name, value in data.items() if value is not None}
    if not data:
        raise HTTPException(status_code=422, detail="Provide at least one field to update")
    assignments = ", ".join(f"`{name}` = %s" for name in data)
    keys = (shoe_id,)
    sql = f"UPDATE `shoe` SET {assignments} WHERE `shoe_id` = %s"
    return execute(sql, tuple(data.values()) + keys, action="UPDATE",
                   existence=("SELECT 1 FROM `shoe` WHERE `shoe_id` = %s FOR UPDATE", keys))


def delete_shoe(
    shoe_id: str,
):
    keys = (shoe_id,)
    return execute("DELETE FROM `shoe` WHERE `shoe_id` = %s", keys, action="DELETE",
                   existence=("SELECT 1 FROM `shoe` WHERE `shoe_id` = %s FOR UPDATE", keys))
