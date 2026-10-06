from fastapi import HTTPException

from services._database import execute


def create_purchase(
    shoe_shoe_id: str,
    user_user_id: str,
    purchase_id: str,
    store_store_id: str,
    sale_price: str | None,
    payment_id: str | None,
    quantity: str | None,
):
    data = {
        "shoe_shoe_id": shoe_shoe_id,
        "user_user_id": user_user_id,
        "purchase_id": purchase_id,
        "store_store_id": store_store_id,
        "sale_price": sale_price,
        "payment_id": payment_id,
        "quantity": quantity,
    }
    data = {name: value for name, value in data.items() if value is not None}
    columns = ", ".join(f"`{name}`" for name in data)
    placeholders = ", ".join("%s" for _ in data)
    sql = f"INSERT INTO `purchase` ({columns}) VALUES ({placeholders})"
    return execute(sql, tuple(data.values()), action="CREATE")


def read_purchase():
    return execute("SELECT * FROM `purchase`")


def read_purchase_for_user(user_user_id: str):
    return execute(
        "SELECT * FROM `purchase` WHERE `user_user_id` = %s",
        (user_user_id,),
    )


def update_purchase(
    shoe_shoe_id: str,
    user_user_id: str,
    purchase_id: str,
    store_store_id: str,
    sale_price: str | None = None,
    payment_id: str | None = None,
    quantity: str | None = None,
):
    data = {
        "sale_price": sale_price,
        "payment_id": payment_id,
        "quantity": quantity,
    }
    data = {name: value for name, value in data.items() if value is not None}
    if not data:
        raise HTTPException(status_code=422, detail="Provide at least one field to update")
    assignments = ", ".join(f"`{name}` = %s" for name in data)
    keys = (shoe_shoe_id, user_user_id, purchase_id, store_store_id)
    sql = f"UPDATE `purchase` SET {assignments} WHERE `shoe_shoe_id` = %s AND `user_user_id` = %s AND `purchase_id` = %s AND `store_store_id` = %s"
    return execute(sql, tuple(data.values()) + keys, action="UPDATE",
                   existence=("SELECT 1 FROM `purchase` WHERE `shoe_shoe_id` = %s AND `user_user_id` = %s AND `purchase_id` = %s AND `store_store_id` = %s FOR UPDATE", keys))


def delete_purchase(
    shoe_shoe_id: str,
    user_user_id: str,
    purchase_id: str,
    store_store_id: str,
):
    keys = (shoe_shoe_id, user_user_id, purchase_id, store_store_id)
    return execute("DELETE FROM `purchase` WHERE `shoe_shoe_id` = %s AND `user_user_id` = %s AND `purchase_id` = %s AND `store_store_id` = %s", keys, action="DELETE",
                   existence=("SELECT 1 FROM `purchase` WHERE `shoe_shoe_id` = %s AND `user_user_id` = %s AND `purchase_id` = %s AND `store_store_id` = %s FOR UPDATE", keys))
