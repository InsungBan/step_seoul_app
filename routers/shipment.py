from fastapi import APIRouter, Form

from services.shipment_service import create_shipment, read_shipment, read_shipment_for_shoe, update_shipment, delete_shipment

router = APIRouter(prefix="/shipment", tags=["shipment"])


@router.post("/upload")
def upload(
    shoe_shoe_id: str = Form(..., max_length=45),
    employee_employee_id: str = Form(..., max_length=20),
    shipment_id: str = Form(..., max_length=45),
    delivery_status: str | None = Form(None, max_length=45),
    delivery_quantity: int | None = Form(None, ge=-2147483648, le=2147483647),
    store_store_id: str = Form(..., max_length=20),
):
    return create_shipment(shoe_shoe_id, employee_employee_id, shipment_id, delivery_status, delivery_quantity, store_store_id)


@router.get("/select")
def select():
    return read_shipment()


@router.get("/select/shoe/{shoe_id}")
def select_for_shoe(shoe_id: str):
    return read_shipment_for_shoe(shoe_id)


@router.put("/update/{shoe_shoe_id}/{employee_employee_id}/{shipment_id}/{store_store_id}")
def update(
    shoe_shoe_id: str,
    employee_employee_id: str,
    shipment_id: str,
    store_store_id: str,
    delivery_status: str | None = Form(None, max_length=45),
    delivery_quantity: int | None = Form(None, ge=-2147483648, le=2147483647),
):
    return update_shipment(shoe_shoe_id, employee_employee_id, shipment_id, store_store_id, delivery_status, delivery_quantity)


@router.delete("/delete/{shoe_shoe_id}/{employee_employee_id}/{shipment_id}/{store_store_id}")
def delete(
    shoe_shoe_id: str,
    employee_employee_id: str,
    shipment_id: str,
    store_store_id: str,
):
    return delete_shipment(shoe_shoe_id, employee_employee_id, shipment_id, store_store_id)
