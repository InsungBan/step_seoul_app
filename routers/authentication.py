from fastapi import APIRouter, Form
from pydantic import BaseModel, Field

from services.authentication_service import authenticate_account, create_authentication, read_authentication, update_authentication, delete_authentication

router = APIRouter(prefix="/authentication", tags=["authentication"])


class LoginRequest(BaseModel):
    account_id: str = Field(min_length=1, max_length=20)
    password: str = Field(min_length=1, max_length=128)


@router.post("/login")
def login(payload: LoginRequest):
    return authenticate_account(payload.account_id.strip(), payload.password)


@router.post("/upload")
def upload(
    user_user_id: str = Form(..., max_length=12),
    employee_employee_id: str = Form(..., max_length=20),
    authentication_id: str = Form(..., max_length=45),
    authentication_date: str | None = Form(None, max_length=45),
):
    return create_authentication(user_user_id, employee_employee_id, authentication_id, authentication_date)


@router.get("/select")
def select():
    return read_authentication()


@router.put("/update/{user_user_id}/{employee_employee_id}/{authentication_id}")
def update(
    user_user_id: str,
    employee_employee_id: str,
    authentication_id: str,
    authentication_date: str | None = Form(None, max_length=45),
):
    return update_authentication(user_user_id, employee_employee_id, authentication_id, authentication_date)


@router.delete("/delete/{user_user_id}/{employee_employee_id}/{authentication_id}")
def delete(
    user_user_id: str,
    employee_employee_id: str,
    authentication_id: str,
):
    return delete_authentication(user_user_id, employee_employee_id, authentication_id)
