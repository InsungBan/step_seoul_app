from fastapi import APIRouter, Form
from pydantic import BaseModel, Field

from services.refund_service import create_refund, read_refund, update_refund, delete_refund
from services.refund_request_service import create_refund_request

router = APIRouter(prefix="/refund", tags=["refund"])


class RefundRequest(BaseModel):
    user_id: str = Field(min_length=1, max_length=12)
    order_id: str = Field(min_length=1, max_length=45)
    shoe_id: str = Field(min_length=1, max_length=20)
    quantity: int = Field(ge=1, le=100)
    reason: str = Field(min_length=1, max_length=45)
    detail_reason: str | None = Field(default=None, max_length=200)


@router.post("/request")
def request_refund(payload: RefundRequest):
    return create_refund_request(**payload.model_dump())


@router.post("/upload")
def upload(
    user_user_id: str = Form(..., max_length=12),
    employee_employee_id: str = Form(..., max_length=20),
    refund_id: str = Form(..., max_length=45),
    refund_amount: str | None = Form(None, max_length=45),
    refund_quantity: str | None = Form(None, max_length=45),
    refund_reason: str | None = Form(None, max_length=45),
    refund_cardnumber: int | None = Form(None, ge=-2147483648, le=2147483647),
):
    return create_refund(user_user_id, employee_employee_id, refund_id, refund_amount, refund_quantity, refund_reason, refund_cardnumber)


@router.get("/select")
def select():
    return read_refund()


@router.put("/update/{user_user_id}/{employee_employee_id}/{refund_id}")
def update(
    user_user_id: str,
    employee_employee_id: str,
    refund_id: str,
    refund_amount: str | None = Form(None, max_length=45),
    refund_quantity: str | None = Form(None, max_length=45),
    refund_reason: str | None = Form(None, max_length=45),
    refund_cardnumber: int | None = Form(None, ge=-2147483648, le=2147483647),
):
    return update_refund(user_user_id, employee_employee_id, refund_id, refund_amount, refund_quantity, refund_reason, refund_cardnumber)


@router.delete("/delete/{user_user_id}/{employee_employee_id}/{refund_id}")
def delete(
    user_user_id: str,
    employee_employee_id: str,
    refund_id: str,
):
    return delete_refund(user_user_id, employee_employee_id, refund_id)
