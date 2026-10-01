from fastapi import APIRouter, Form

from services.refund_service import create_refund, read_refund, update_refund, delete_refund

router = APIRouter(prefix="/refund", tags=["refund"])


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
