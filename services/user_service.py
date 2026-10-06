from datetime import datetime

from fastapi import HTTPException

from services._database import execute
from services.password_service import hash_password


def create_user(
    user_id: str,
    user_name: str | None,
    user_phone: str | None,
    user_pw: str | None,
    user_email: str | None,
    join_date: str | None,
):
    if join_date is None:
        join_date = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    data = {
        "user_id": user_id,
        "user_name": user_name,
        "user_phone": user_phone,
        "user_pw": hash_password(user_pw) if user_pw else None,
        "user_email": user_email,
        "join_date": join_date,
    }
    data = {name: value for name, value in data.items() if value is not None}
    columns = ", ".join(f"`{name}`" for name in data)
    placeholders = ", ".join("%s" for _ in data)
    sql = f"INSERT INTO `user` ({columns}) VALUES ({placeholders})"
    return execute(sql, tuple(data.values()), action="CREATE")


def read_user():
    return execute(
        "SELECT `user_id`, `user_name`, `user_phone`, `user_email`, `join_date` "
        "FROM `user` ORDER BY `join_date`"
    )


def user_exists(user_id: str):
    rows = execute(
        "SELECT 1 AS `exists` FROM `user` WHERE `user_id` = %s LIMIT 1",
        (user_id,),
    )["result"]
    return {"result": {"exists": bool(rows)}}


def update_user(
    user_id: str,
    user_name: str | None = None,
    user_phone: str | None = None,
    user_pw: str | None = None,
    user_email: str | None = None,
    join_date: str | None = None,
):
    data = {
        "user_name": user_name,
        "user_phone": user_phone,
        "user_pw": hash_password(user_pw) if user_pw else None,
        "user_email": user_email,
        "join_date": join_date,
    }
    data = {name: value for name, value in data.items() if value is not None}
    if not data:
        raise HTTPException(status_code=422, detail="Provide at least one field to update")
    assignments = ", ".join(f"`{name}` = %s" for name in data)
    keys = (user_id,)
    sql = f"UPDATE `user` SET {assignments} WHERE `user_id` = %s"
    return execute(sql, tuple(data.values()) + keys, action="UPDATE",
                   existence=("SELECT 1 FROM `user` WHERE `user_id` = %s FOR UPDATE", keys))


def delete_user(
    user_id: str,
):
    keys = (user_id,)
    return execute("DELETE FROM `user` WHERE `user_id` = %s", keys, action="DELETE",
                   existence=("SELECT 1 FROM `user` WHERE `user_id` = %s FOR UPDATE", keys))
