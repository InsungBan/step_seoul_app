from fastapi import HTTPException

from services._database import execute


def create_cart(
    user_user_id: str,
    shoe_shoe_id: str,
    cart_id: str,
    added_at: str | None,
):
    data = {
        "user_user_id": user_user_id,
        "shoe_shoe_id": shoe_shoe_id,
        "cart_id": cart_id,
        "added_at": added_at,
    }
    data = {name: value for name, value in data.items() if value is not None}
    columns = ", ".join(f"`{name}`" for name in data)
    placeholders = ", ".join("%s" for _ in data)
    sql = f"INSERT INTO `cart` ({columns}) VALUES ({placeholders})"
    return execute(sql, tuple(data.values()), action="CREATE")


def read_cart():
    return execute("SELECT * FROM `cart`")


def update_cart(
    user_user_id: str,
    shoe_shoe_id: str,
    cart_id: str,
    added_at: str | None = None,
):
    data = {
        "added_at": added_at,
    }
    data = {name: value for name, value in data.items() if value is not None}
    if not data:
        raise HTTPException(status_code=422, detail="Provide at least one field to update")
    assignments = ", ".join(f"`{name}` = %s" for name in data)
    keys = (user_user_id, shoe_shoe_id, cart_id,)
    sql = f"UPDATE `cart` SET {assignments} WHERE `user_user_id` = %s AND `shoe_shoe_id` = %s AND `cart_id` = %s"
    return execute(sql, tuple(data.values()) + keys, action="UPDATE",
                   existence=("SELECT 1 FROM `cart` WHERE `user_user_id` = %s AND `shoe_shoe_id` = %s AND `cart_id` = %s FOR UPDATE", keys))


def delete_cart(
    user_user_id: str,
    shoe_shoe_id: str,
    cart_id: str,
):
    keys = (user_user_id, shoe_shoe_id, cart_id,)
    return execute("DELETE FROM `cart` WHERE `user_user_id` = %s AND `shoe_shoe_id` = %s AND `cart_id` = %s", keys, action="DELETE",
                   existence=("SELECT 1 FROM `cart` WHERE `user_user_id` = %s AND `shoe_shoe_id` = %s AND `cart_id` = %s FOR UPDATE", keys))
