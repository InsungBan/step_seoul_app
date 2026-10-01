from fastapi import HTTPException

from services._database import execute


def create_manufacturing(
    shoe_shoe_id: str,
    shoe_manufacturer_manufacturer_id: str,
    manufacturing_id: str,
    manufacturing_date: str | None,
):
    data = {
        "shoe_shoe_id": shoe_shoe_id,
        "shoe_manufacturer_manufacturer_id": shoe_manufacturer_manufacturer_id,
        "manufacturing_id": manufacturing_id,
        "manufacturing_date": manufacturing_date,
    }
    data = {name: value for name, value in data.items() if value is not None}
    columns = ", ".join(f"`{name}`" for name in data)
    placeholders = ", ".join("%s" for _ in data)
    sql = f"INSERT INTO `manufacturing` ({columns}) VALUES ({placeholders})"
    return execute(sql, tuple(data.values()), action="CREATE")


def read_manufacturing():
    return execute("SELECT * FROM `manufacturing`")


def update_manufacturing(
    shoe_shoe_id: str,
    shoe_manufacturer_manufacturer_id: str,
    manufacturing_id: str,
    manufacturing_date: str | None = None,
):
    data = {
        "manufacturing_date": manufacturing_date,
    }
    data = {name: value for name, value in data.items() if value is not None}
    if not data:
        raise HTTPException(status_code=422, detail="Provide at least one field to update")
    assignments = ", ".join(f"`{name}` = %s" for name in data)
    keys = (shoe_shoe_id, shoe_manufacturer_manufacturer_id, manufacturing_id,)
    sql = f"UPDATE `manufacturing` SET {assignments} WHERE `shoe_shoe_id` = %s AND `shoe_manufacturer_manufacturer_id` = %s AND `manufacturing_id` = %s"
    return execute(sql, tuple(data.values()) + keys, action="UPDATE",
                   existence=("SELECT 1 FROM `manufacturing` WHERE `shoe_shoe_id` = %s AND `shoe_manufacturer_manufacturer_id` = %s AND `manufacturing_id` = %s FOR UPDATE", keys))


def delete_manufacturing(
    shoe_shoe_id: str,
    shoe_manufacturer_manufacturer_id: str,
    manufacturing_id: str,
):
    keys = (shoe_shoe_id, shoe_manufacturer_manufacturer_id, manufacturing_id,)
    return execute("DELETE FROM `manufacturing` WHERE `shoe_shoe_id` = %s AND `shoe_manufacturer_manufacturer_id` = %s AND `manufacturing_id` = %s", keys, action="DELETE",
                   existence=("SELECT 1 FROM `manufacturing` WHERE `shoe_shoe_id` = %s AND `shoe_manufacturer_manufacturer_id` = %s AND `manufacturing_id` = %s FOR UPDATE", keys))
