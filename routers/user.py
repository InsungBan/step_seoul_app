from fastapi import APIRouter, Form

from services.user_service import create_user, read_user, update_user, delete_user

router = APIRouter(prefix="/user", tags=["user"])


@router.post("/upload")
def upload(
    user_id: str = Form(..., max_length=12),
    user_name: str | None = Form(None, max_length=45),
    user_phone: str | None = Form(None, max_length=20),
    user_pw: str | None = Form(None, max_length=45),
    user_email: str | None = Form(None, max_length=45),
    join_date: str | None = None,
):
    return create_user(user_id, user_name, user_phone, user_pw, user_email, join_date)


@router.get("/select")
def select():
    return read_user()


@router.put("/update/{user_id}")
def update(
    user_id: str,
    user_name: str | None = Form(None, max_length=45),
    user_phone: str | None = Form(None, max_length=20),
    user_pw: str | None = Form(None, max_length=45),
    user_email: str | None = Form(None, max_length=45),
    join_date: str | None = Form(None, max_length=45),
):
    return update_user(user_id, user_name, user_phone, user_pw, user_email, join_date)


@router.delete("/delete/{user_id}")
def delete(
    user_id: str,
):
    return delete_user(user_id)
