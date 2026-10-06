import pymysql
from fastapi import HTTPException

from db.database import db
from services._database import execute
from services.password_service import hash_password, verify_password


def authenticate_account(account_id: str, password: str):
    """Validate credentials on the server without returning password fields."""
    conn = db()
    try:
        with conn.cursor(pymysql.cursors.DictCursor) as cursor:
            cursor.execute(
                "SELECT `user_id` AS account_id, `user_pw` AS password "
                "FROM `user` WHERE `user_id` = %s LIMIT 1",
                (account_id,),
            )
            account = cursor.fetchone()
            role = "customer"
            if account is None:
                cursor.execute(
                    "SELECT `employee_id` AS account_id, `employee_pw` AS password, "
                    "`employee_department` AS department "
                    "FROM `employee` WHERE `employee_id` = %s LIMIT 1",
                    (account_id,),
                )
                account = cursor.fetchone()
                role = (
                    "executive"
                    if account and str(account.get("department") or "").strip() == "본사"
                    else "employee"
                )
            if account is None or not verify_password(password, account.get("password")):
                raise HTTPException(status_code=401, detail="Invalid ID or password")

            # Compatibility for a server upgraded before the startup migration ran.
            stored = str(account.get("password") or "")
            if not stored.startswith("pbkdf2_sha256$"):
                table = "user" if role == "customer" else "employee"
                id_column = "user_id" if role == "customer" else "employee_id"
                password_column = "user_pw" if role == "customer" else "employee_pw"
                cursor.execute(
                    f"UPDATE `{table}` SET `{password_column}` = %s WHERE `{id_column}` = %s",
                    (hash_password(password), account_id),
                )
        conn.commit()
        return {"result": {"account_id": account_id, "role": role}}
    except HTTPException:
        conn.rollback()
        raise
    except pymysql.MySQLError:
        conn.rollback()
        raise HTTPException(status_code=500, detail="Could not authenticate account") from None
    finally:
        conn.close()


def create_authentication(
    user_user_id: str,
    employee_employee_id: str,
    authentication_id: str,
    authentication_date: str | None,
):
    data = {
        "user_user_id": user_user_id,
        "employee_employee_id": employee_employee_id,
        "authentication_id": authentication_id,
        "authentication_date": authentication_date,
    }
    data = {name: value for name, value in data.items() if value is not None}
    columns = ", ".join(f"`{name}`" for name in data)
    placeholders = ", ".join("%s" for _ in data)
    sql = f"INSERT INTO `authentication` ({columns}) VALUES ({placeholders})"
    return execute(sql, tuple(data.values()), action="CREATE")


def read_authentication():
    return execute("SELECT * FROM `authentication`")


def update_authentication(
    user_user_id: str,
    employee_employee_id: str,
    authentication_id: str,
    authentication_date: str | None = None,
):
    data = {
        "authentication_date": authentication_date,
    }
    data = {name: value for name, value in data.items() if value is not None}
    if not data:
        raise HTTPException(status_code=422, detail="Provide at least one field to update")
    assignments = ", ".join(f"`{name}` = %s" for name in data)
    keys = (user_user_id, employee_employee_id, authentication_id,)
    sql = f"UPDATE `authentication` SET {assignments} WHERE `user_user_id` = %s AND `employee_employee_id` = %s AND `authentication_id` = %s"
    return execute(sql, tuple(data.values()) + keys, action="UPDATE",
                   existence=("SELECT 1 FROM `authentication` WHERE `user_user_id` = %s AND `employee_employee_id` = %s AND `authentication_id` = %s FOR UPDATE", keys))


def delete_authentication(
    user_user_id: str,
    employee_employee_id: str,
    authentication_id: str,
):
    keys = (user_user_id, employee_employee_id, authentication_id,)
    return execute("DELETE FROM `authentication` WHERE `user_user_id` = %s AND `employee_employee_id` = %s AND `authentication_id` = %s", keys, action="DELETE",
                   existence=("SELECT 1 FROM `authentication` WHERE `user_user_id` = %s AND `employee_employee_id` = %s AND `authentication_id` = %s FOR UPDATE", keys))
