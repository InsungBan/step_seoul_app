from decimal import Decimal

from fastapi import HTTPException

from services._database import execute


def create_store(
    store_id: str,
    latitude: Decimal | None,
    longitude: Decimal | None,
    district_name: str | None,
    agency_name: str | None,
    phone: str | None,
):
    data = {
        "store_id": store_id,
        "latitude": latitude,
        "longitude": longitude,
        "district_name": district_name,
        "agency_name": agency_name,
        "phone": phone,
    }
    data = {name: value for name, value in data.items() if value is not None}
    columns = ", ".join(f"`{name}`" for name in data)
    placeholders = ", ".join("%s" for _ in data)
    sql = f"INSERT INTO `store` ({columns}) VALUES ({placeholders})"
    return execute(sql, tuple(data.values()), action="CREATE")


def read_store():
    return execute("SELECT * FROM `store`")


def update_store(
    store_id: str,
    latitude: Decimal | None = None,
    longitude: Decimal | None = None,
    district_name: str | None = None,
    agency_name: str | None = None,
    phone: str | None = None,
):
    data = {
        "latitude": latitude,
        "longitude": longitude,
        "district_name": district_name,
        "agency_name": agency_name,
        "phone": phone,
    }
    data = {name: value for name, value in data.items() if value is not None}
    if not data:
        raise HTTPException(status_code=422, detail="Provide at least one field to update")
    assignments = ", ".join(f"`{name}` = %s" for name in data)
    keys = (store_id,)
    sql = f"UPDATE `store` SET {assignments} WHERE `store_id` = %s"
    return execute(sql, tuple(data.values()) + keys, action="UPDATE",
                   existence=("SELECT 1 FROM `store` WHERE `store_id` = %s FOR UPDATE", keys))


def delete_store(
    store_id: str,
):
    keys = (store_id,)
    return execute("DELETE FROM `store` WHERE `store_id` = %s", keys, action="DELETE",
                   existence=("SELECT 1 FROM `store` WHERE `store_id` = %s FOR UPDATE", keys))
