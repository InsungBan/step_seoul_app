from fastapi import HTTPException

from services._database import execute
from services.shoe_schema import ensure_shoe_schema


def ensure_shoe_category_column():
    """Retain the existing startup hook while preparing all shoe columns."""
    return ensure_shoe_schema()


def _image_url(shoe_img_url: str | None, shoe_image_url: str | None) -> str | None:
    if (
        shoe_img_url is not None
        and shoe_image_url is not None
        and shoe_img_url != shoe_image_url
    ):
        raise HTTPException(status_code=422, detail="shoe_img_url and shoe_image_url must match")
    return shoe_img_url if shoe_img_url is not None else shoe_image_url


def create_shoe(
    shoe_id: str,
    brand_name: str | None,
    shoe_category: str | None,
    shoe_image_url: str | None,
    shoe_price: str | None,
    standard_stock: int | None,
    stock_quantity: int | None,
    shoe_img_url: str | None = None,
    shoe_name: str | None = None,
):
    image_url = _image_url(shoe_img_url, shoe_image_url)
    data = {
        "shoe_id": shoe_id,
        "brand_name": brand_name,
        "shoe_name": shoe_name,
        "shoe_category": shoe_category,
        "shoe_img_url": image_url,
        "shoe_image_url": image_url,
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
        clauses.append("(`shoe_id` LIKE %s OR `brand_name` LIKE %s OR `shoe_name` LIKE %s)")
        params.extend((keyword, keyword, keyword))
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
    shoe_img_url: str | None = None,
    shoe_name: str | None = None,
):
    image_url = _image_url(shoe_img_url, shoe_image_url)
    data = {
        "brand_name": brand_name,
        "shoe_name": shoe_name,
        "shoe_category": shoe_category,
        "shoe_img_url": image_url,
        "shoe_image_url": image_url,
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
