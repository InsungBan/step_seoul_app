from fastapi import APIRouter, Form

from services.purchase_order_service import create_purchase_order, read_purchase_order, update_purchase_order, delete_purchase_order

router = APIRouter(prefix="/purchase_order", tags=["purchase_order"])


@router.post("/upload")
def upload(
    shoe_manufacturer_manufacturer_id: str = Form(..., max_length=20),
    approval_approval_id: str = Form(..., max_length=20),
    order_date: str | None = Form(None, max_length=45),
    get_amount: str | None = Form(None, max_length=45),
    order_id: str = Form(..., max_length=45),
    order_quantity: str | None = Form(None, max_length=45),
    shoe_shoe_id: str = Form(..., max_length=20),
):
    return create_purchase_order(shoe_manufacturer_manufacturer_id, approval_approval_id, order_date, get_amount, order_id, order_quantity, shoe_shoe_id)


@router.get("/select")
def select():
    return read_purchase_order()


@router.put("/update/{shoe_manufacturer_manufacturer_id}/{approval_approval_id}/{order_id}/{shoe_shoe_id}")
def update(
    shoe_manufacturer_manufacturer_id: str,
    approval_approval_id: str,
    order_id: str,
    shoe_shoe_id: str,
    order_date: str | None = Form(None, max_length=45),
    get_amount: str | None = Form(None, max_length=45),
    order_quantity: str | None = Form(None, max_length=45),
):
    return update_purchase_order(shoe_manufacturer_manufacturer_id, approval_approval_id, order_id, shoe_shoe_id, order_date, get_amount, order_quantity)


@router.delete("/delete/{shoe_manufacturer_manufacturer_id}/{approval_approval_id}/{order_id}/{shoe_shoe_id}")
def delete(
    shoe_manufacturer_manufacturer_id: str,
    approval_approval_id: str,
    order_id: str,
    shoe_shoe_id: str,
):
    return delete_purchase_order(shoe_manufacturer_manufacturer_id, approval_approval_id, order_id, shoe_shoe_id)
