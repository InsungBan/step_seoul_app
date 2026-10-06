from fastapi import APIRouter, Form

from services.get_order_service import create_get_order, read_get_order, update_get_order, delete_get_order

router = APIRouter(prefix="/get_order", tags=["get_order"])


@router.post("/upload")
def upload(
    shoe_shoe_id: str = Form(..., max_length=45),
    employee_employee_id: str = Form(..., max_length=20),
    get_order_id: str = Form(..., max_length=45),
    get_order_quantity: str | None = Form(None, max_length=45),
    get_order_status: str | None = Form(None, max_length=45),
    get_order_date: str | None = Form(None, max_length=45),
    shoe_manufacturer_manufacturer_id: str = Form(..., max_length=20),
):
    return create_get_order(shoe_shoe_id, employee_employee_id, get_order_id, get_order_quantity, get_order_status, get_order_date, shoe_manufacturer_manufacturer_id)


@router.get("/select")
def select():
    return read_get_order()


@router.put("/update/{shoe_shoe_id}/{employee_employee_id}/{get_order_id}/{shoe_manufacturer_manufacturer_id}")
def update(
    shoe_shoe_id: str,
    employee_employee_id: str,
    get_order_id: str,
    shoe_manufacturer_manufacturer_id: str,
    get_order_quantity: str | None = Form(None, max_length=45),
    get_order_status: str | None = Form(None, max_length=45),
    get_order_date: str | None = Form(None, max_length=45),
):
    return update_get_order(shoe_shoe_id, employee_employee_id, get_order_id, shoe_manufacturer_manufacturer_id, get_order_quantity, get_order_status, get_order_date)


@router.delete("/delete/{shoe_shoe_id}/{employee_employee_id}/{get_order_id}/{shoe_manufacturer_manufacturer_id}")
def delete(
    shoe_shoe_id: str,
    employee_employee_id: str,
    get_order_id: str,
    shoe_manufacturer_manufacturer_id: str,
):
    return delete_get_order(shoe_shoe_id, employee_employee_id, get_order_id, shoe_manufacturer_manufacturer_id)
