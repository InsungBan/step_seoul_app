import pymysql
from fastapi import HTTPException

from db.database import db


def read_customer_profile(user_id: str):
    conn = None
    try:
        conn = db()
        with conn.cursor(pymysql.cursors.DictCursor) as cursor:
            cursor.execute(
                "SELECT `user_id`, `user_name`, `user_phone`, `user_email`, `join_date` FROM `user` WHERE `user_id` = %s",
                (user_id,),
            )
            profile = cursor.fetchone()
            if profile is None:
                raise HTTPException(status_code=404, detail="User not found")
            return {"result": profile}
    except HTTPException:
        raise
    except pymysql.MySQLError:
        raise HTTPException(status_code=500, detail="Could not load profile") from None
    finally:
        if conn is not None:
            conn.close()


def update_customer_profile(
    user_id: str,
    user_name: str,
    user_phone: str,
    current_password: str | None,
    new_password: str | None,
):
    conn = None
    try:
        conn = db()
        with conn.cursor(pymysql.cursors.DictCursor) as cursor:
            cursor.execute("SELECT `user_pw` FROM `user` WHERE `user_id` = %s FOR UPDATE", (user_id,))
            user = cursor.fetchone()
            if user is None:
                raise HTTPException(status_code=404, detail="User not found")
            changes = {"user_name": user_name.strip(), "user_phone": user_phone.strip()}
            if not changes["user_name"] or not changes["user_phone"]:
                raise HTTPException(status_code=422, detail="Name and phone number are required")
            if new_password:
                if not current_password or current_password != user.get("user_pw"):
                    raise HTTPException(status_code=403, detail="Current password does not match")
                if len(new_password) < 8:
                    raise HTTPException(status_code=422, detail="New password must be at least 8 characters")
                changes["user_pw"] = new_password
            assignments = ", ".join(f"`{field}` = %s" for field in changes)
            cursor.execute(
                f"UPDATE `user` SET {assignments} WHERE `user_id` = %s",
                tuple(changes.values()) + (user_id,),
            )
        conn.commit()
        return {"result": {"user_id": user_id, "user_name": changes["user_name"], "user_phone": changes["user_phone"]}}
    except HTTPException:
        if conn is not None:
            conn.rollback()
        raise
    except pymysql.MySQLError:
        if conn is not None:
            conn.rollback()
        raise HTTPException(status_code=500, detail="Could not update profile") from None
    finally:
        if conn is not None:
            conn.close()
