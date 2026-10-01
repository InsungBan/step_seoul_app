from fastapi import APIRouter, Form

from services.payment_service import create_payment, read_payment, update_payment, delete_payment

router = APIRouter(prefix="/payment", tags=["payment"])


@router.post("/upload")
def upload(
    user_user_id: str = Form(..., max_length=12),
    employee_employee_id: str = Form(..., max_length=20),
    payment_id: str = Form(..., max_length=45),
    payment_date: str | None = Form(None, max_length=45),
    payment_amount: int | None = Form(None, ge=-2147483648, le=2147483647),
    payment_status: int | None = Form(None, ge=-128, le=127),
    discount_flag: str | None = Form(None, max_length=45),
):
    return create_payment(user_user_id, employee_employee_id, payment_id, payment_date, payment_amount, payment_status, discount_flag)


@router.get("/select")
def select():
    return read_payment()


@router.put("/update/{user_user_id}/{employee_employee_id}/{payment_id}")
def update(
    user_user_id: str,
    employee_employee_id: str,
    payment_id: str,
    payment_date: str | None = Form(None, max_length=45),
    payment_amount: int | None = Form(None, ge=-2147483648, le=2147483647),
    payment_status: int | None = Form(None, ge=-128, le=127),
    discount_flag: str | None = Form(None, max_length=45),
):
    return update_payment(user_user_id, employee_employee_id, payment_id, payment_date, payment_amount, payment_status, discount_flag)


@router.delete("/delete/{user_user_id}/{employee_employee_id}/{payment_id}")
def delete(
    user_user_id: str,
    employee_employee_id: str,
    payment_id: str,
):
    return delete_payment(user_user_id, employee_employee_id, payment_id)
