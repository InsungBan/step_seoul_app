from fastapi import APIRouter, Form

from services.receive_service import create_receive, read_receive, update_receive, delete_receive

router = APIRouter(prefix="/receive", tags=["receive"])


@router.post("/upload")
def upload(
    store_store_id: str = Form(..., max_length=20),
    user_user_id: str = Form(..., max_length=12),
    employee_employee_id: str = Form(..., max_length=20),
    receive_id: str = Form(..., max_length=45),
    receive_date: str | None = Form(None, max_length=45),
    receive_quantity: str | None = Form(None, max_length=45),
    receive_verification_code: str | None = Form(None, max_length=45),
    receive_status: str | None = Form(None, max_length=45),
    receive_verification_status: int | None = Form(None, ge=-128, le=127),
    receive_expdate: str | None = Form(None, max_length=45),
    receive_payment_id: str | None = Form(None, max_length=45),
):
    return create_receive(store_store_id, user_user_id, employee_employee_id, receive_id, receive_date, receive_quantity, receive_verification_code, receive_status, receive_verification_status, receive_expdate, receive_payment_id)


@router.get("/select")
def select():
    return read_receive()


@router.put("/update/{store_store_id}/{user_user_id}/{employee_employee_id}/{receive_id}")
def update(
    store_store_id: str,
    user_user_id: str,
    employee_employee_id: str,
    receive_id: str,
    receive_date: str | None = Form(None, max_length=45),
    receive_quantity: str | None = Form(None, max_length=45),
    receive_verification_code: str | None = Form(None, max_length=45),
    receive_status: str | None = Form(None, max_length=45),
    receive_verification_status: int | None = Form(None, ge=-128, le=127),
    receive_expdate: str | None = Form(None, max_length=45),
    receive_payment_id: str | None = Form(None, max_length=45),
):
    return update_receive(store_store_id, user_user_id, employee_employee_id, receive_id, receive_date, receive_quantity, receive_verification_code, receive_status, receive_verification_status, receive_expdate, receive_payment_id)


@router.delete("/delete/{store_store_id}/{user_user_id}/{employee_employee_id}/{receive_id}")
def delete(
    store_store_id: str,
    user_user_id: str,
    employee_employee_id: str,
    receive_id: str,
):
    return delete_receive(store_store_id, user_user_id, employee_employee_id, receive_id)
