from fastapi import APIRouter, Form
from pydantic import BaseModel, Field

from services.user_service import create_user, read_user, update_user, delete_user
from services.profile_service import read_customer_profile, update_customer_profile

router = APIRouter(prefix="/user", tags=["user"])


class CustomerProfileUpdate(BaseModel):
    user_name: str = Field(min_length=1, max_length=45)
    user_phone: str = Field(min_length=1, max_length=20)
    current_password: str | None = Field(default=None, max_length=45)
    new_password: str | None = Field(default=None, max_length=45)


@router.get("/profile/{user_id}")
def profile(user_id: str):
    return read_customer_profile(user_id)


@router.put("/profile/{user_id}")
def update_profile(user_id: str, payload: CustomerProfileUpdate):
    return update_customer_profile(user_id=user_id, **payload.model_dump())


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
