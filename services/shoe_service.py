from fastapi import HTTPException

from services._database import execute


def create_shoe(
    shoe_id: str,
    brand_name: str | None,
    shoe_price: str | None,
    standard_stock: int | None,
    stock_quantity: int | None,
):
    data = {
        "shoe_id": shoe_id,
        "brand_name": brand_name,
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


def update_shoe(
    shoe_id: str,
    brand_name: str | None = None,
    shoe_price: str | None = None,
    standard_stock: int | None = None,
    stock_quantity: int | None = None,
):
    data = {
        "brand_name": brand_name,
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
