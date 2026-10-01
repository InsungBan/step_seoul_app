from fastapi import HTTPException

from services._database import execute


def create_shoe_manufacturer(
    manufacturer_id: str,
    manufacturer_name: str | None,
):
    data = {
        "manufacturer_id": manufacturer_id,
        "manufacturer_name": manufacturer_name,
    }
    data = {name: value for name, value in data.items() if value is not None}
    columns = ", ".join(f"`{name}`" for name in data)
    placeholders = ", ".join("%s" for _ in data)
    sql = f"INSERT INTO `shoe_manufacturer` ({columns}) VALUES ({placeholders})"
    return execute(sql, tuple(data.values()), action="CREATE")


def read_shoe_manufacturer():
    return execute("SELECT * FROM `shoe_manufacturer`")


def update_shoe_manufacturer(
    manufacturer_id: str,
    manufacturer_name: str | None = None,
):
    data = {
        "manufacturer_name": manufacturer_name,
    }
    data = {name: value for name, value in data.items() if value is not None}
    if not data:
        raise HTTPException(status_code=422, detail="Provide at least one field to update")
    assignments = ", ".join(f"`{name}` = %s" for name in data)
    keys = (manufacturer_id,)
    sql = f"UPDATE `shoe_manufacturer` SET {assignments} WHERE `manufacturer_id` = %s"
    return execute(sql, tuple(data.values()) + keys, action="UPDATE",
                   existence=("SELECT 1 FROM `shoe_manufacturer` WHERE `manufacturer_id` = %s FOR UPDATE", keys))


def delete_shoe_manufacturer(
    manufacturer_id: str,
):
    keys = (manufacturer_id,)
    return execute("DELETE FROM `shoe_manufacturer` WHERE `manufacturer_id` = %s", keys, action="DELETE",
                   existence=("SELECT 1 FROM `shoe_manufacturer` WHERE `manufacturer_id` = %s FOR UPDATE", keys))
