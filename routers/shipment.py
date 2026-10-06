from fastapi import APIRouter, Form
from pydantic import BaseModel, Field
from services.shipment_service import dispatch_shipments

from services.shipment_service import create_shipment, read_shipment, update_shipment, delete_shipment

router = APIRouter(prefix="/shipment", tags=["shipment"])


class ShipmentKey(BaseModel):
    shoe_shoe_id: str = Field(min_length=1, max_length=45)
    employee_employee_id: str = Field(min_length=1, max_length=20)
    shipment_id: str = Field(min_length=1, max_length=45)
    store_store_id: str = Field(min_length=1, max_length=20)


class ShipmentBatch(BaseModel):
    shipments: list[ShipmentKey] = Field(min_length=1, max_length=500)


@router.put('/dispatch')
def dispatch(payload: ShipmentBatch):
    return dispatch_shipments([item.model_dump() for item in payload.shipments])


@router.post("/upload")
def upload(
    shoe_shoe_id: str = Form(..., max_length=20),
    employee_employee_id: str = Form(..., max_length=20),
    shipment_id: str = Form(..., max_length=45),
    delivery_status: str | None = Form(None, max_length=45),
    delivery_quantity: int | None = Form(None, ge=-2147483648, le=2147483647),
    store_store_id: str = Form(..., max_length=20),
    purchase_purchase_id: str | None = Form(None, max_length=45),
):
    return create_shipment(shoe_shoe_id, employee_employee_id, shipment_id, delivery_status, delivery_quantity, store_store_id, purchase_purchase_id)


@router.get("/select")
def select():
    return read_shipment()


@router.put("/update/{shoe_shoe_id}/{employee_employee_id}/{shipment_id}/{store_store_id}")
def update(
    shoe_shoe_id: str,
    employee_employee_id: str,
    shipment_id: str,
    store_store_id: str,
    delivery_status: str | None = Form(None, max_length=45),
    delivery_quantity: int | None = Form(None, ge=-2147483648, le=2147483647),
    purchase_purchase_id: str | None = Form(None, max_length=45),
):
    return update_shipment(shoe_shoe_id, employee_employee_id, shipment_id, store_store_id, delivery_status, delivery_quantity, purchase_purchase_id)


@router.delete("/delete/{shoe_shoe_id}/{employee_employee_id}/{shipment_id}/{store_store_id}")
def delete(
    shoe_shoe_id: str,
    employee_employee_id: str,
    shipment_id: str,
    store_store_id: str,
):
    return delete_shipment(shoe_shoe_id, employee_employee_id, shipment_id, store_store_id)
