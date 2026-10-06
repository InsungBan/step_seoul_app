from fastapi import APIRouter, Form

from services.return_record_service import create_return_record, read_return_record, update_return_record, delete_return_record

router = APIRouter(prefix="/return_record", tags=["return_record"])


@router.post("/upload")
def upload(
    shoe_shoe_id: str = Form(..., max_length=45),
    employee_employee_id: str = Form(..., max_length=20),
    return_id: str = Form(..., max_length=45),
    return_date: str | None = Form(None, max_length=45),
    refund_refund_id: str | None = Form(None, min_length=1, max_length=45),
):
    return create_return_record(shoe_shoe_id, employee_employee_id, return_id, return_date, refund_refund_id)


@router.get("/select")
def select():
    return read_return_record()


@router.put("/update/{shoe_shoe_id}/{employee_employee_id}/{return_id}")
def update(
    shoe_shoe_id: str,
    employee_employee_id: str,
    return_id: str,
    return_date: str | None = Form(None, max_length=45),
    refund_refund_id: str | None = Form(None, min_length=1, max_length=45),
):
    return update_return_record(shoe_shoe_id, employee_employee_id, return_id, return_date, refund_refund_id)


@router.delete("/delete/{shoe_shoe_id}/{employee_employee_id}/{return_id}")
def delete(
    shoe_shoe_id: str,
    employee_employee_id: str,
    return_id: str,
):
    return delete_return_record(shoe_shoe_id, employee_employee_id, return_id)
