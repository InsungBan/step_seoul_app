from fastapi import APIRouter, Form

from services.shipment_service import create_shipment, read_shipment, read_shipment_for_shoe, read_shipment_in_transit, update_shipment, delete_shipment

router = APIRouter(prefix="/shipment", tags=["shipment"])


@router.post("/upload")
def upload(
    shoe_shoe_id: str = Form(..., max_length=20),
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


@router.get("/select/in-transit")
def select_in_transit():
    return read_shipment_in_transit()


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
    pickup_user_id: str | None = Form(None, max_length=12),
    pickup_payment_id: str | None = Form(None, max_length=45),
    receive_id: str | None = Form(None, max_length=45),
    receive_quantity: int | None = Form(None, ge=1, le=2147483647),
    pickup_purchase_id: str | None = Form(None, max_length=45),
):
    return update_shipment(
        shoe_shoe_id,
        employee_employee_id,
        shipment_id,
        store_store_id,
        delivery_status,
        delivery_quantity,
        pickup_user_id,
        pickup_payment_id,
        receive_id,
        receive_quantity,
        pickup_purchase_id,
    )

@router.delete("/delete/{shoe_shoe_id}/{employee_employee_id}/{shipment_id}/{store_store_id}")
def delete(
    shoe_shoe_id: str,
    employee_employee_id: str,
    shipment_id: str,
    store_store_id: str,
):
    return delete_shipment(shoe_shoe_id, employee_employee_id, shipment_id, store_store_id)
