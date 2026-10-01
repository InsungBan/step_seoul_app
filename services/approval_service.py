from fastapi import HTTPException

from services._database import execute


def create_approval(
    approval_id: str,
    approval_name: str | None,
    approval_content: str | None,
):
    data = {
        "approval_id": approval_id,
        "approval_name": approval_name,
        "approval_content": approval_content,
    }
    data = {name: value for name, value in data.items() if value is not None}
    columns = ", ".join(f"`{name}`" for name in data)
    placeholders = ", ".join("%s" for _ in data)
    sql = f"INSERT INTO `approval` ({columns}) VALUES ({placeholders})"
    return execute(sql, tuple(data.values()), action="CREATE")


def read_approval():
    return execute("SELECT * FROM `approval`")


def update_approval(
    approval_id: str,
    approval_name: str | None = None,
    approval_content: str | None = None,
):
    data = {
        "approval_name": approval_name,
        "approval_content": approval_content,
    }
    data = {name: value for name, value in data.items() if value is not None}
    if not data:
        raise HTTPException(status_code=422, detail="Provide at least one field to update")
    assignments = ", ".join(f"`{name}` = %s" for name in data)
    keys = (approval_id,)
    sql = f"UPDATE `approval` SET {assignments} WHERE `approval_id` = %s"
    return execute(sql, tuple(data.values()) + keys, action="UPDATE",
                   existence=("SELECT 1 FROM `approval` WHERE `approval_id` = %s FOR UPDATE", keys))


def delete_approval(
    approval_id: str,
):
    keys = (approval_id,)
    return execute("DELETE FROM `approval` WHERE `approval_id` = %s", keys, action="DELETE",
                   existence=("SELECT 1 FROM `approval` WHERE `approval_id` = %s FOR UPDATE", keys))
