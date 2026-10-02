from fastapi import APIRouter, Form

from services.purchase_service import create_purchase, read_purchase, update_purchase, delete_purchase

router = APIRouter(prefix="/purchase", tags=["purchase"])


@router.post("/upload")
def upload(
    shoe_shoe_id: str = Form(..., max_length=20),
    user_user_id: str = Form(..., max_length=12),
    purchase_id: str = Form(..., max_length=45),
    store_store_id: str = Form(..., max_length=20),
    sale_price: str | None = Form(None, max_length=45),
    payment_id: str | None = Form(None, max_length=45),
    quantity: str | None = Form(None, max_length=45),
):
    return create_purchase(shoe_shoe_id, user_user_id, purchase_id, store_store_id, sale_price, payment_id, quantity)


@router.get("/select")
def select():
    return read_purchase()


@router.put("/update/{shoe_shoe_id}/{user_user_id}/{purchase_id}/{store_store_id}")
def update(
    shoe_shoe_id: str,
    user_user_id: str,
    purchase_id: str,
    store_store_id: str,
    sale_price: str | None = Form(None, max_length=45),
    payment_id: str | None = Form(None, max_length=45),
    quantity: str | None = Form(None, max_length=45),
):
    return update_purchase(shoe_shoe_id, user_user_id, purchase_id, store_store_id, sale_price, payment_id, quantity)


@router.delete("/delete/{shoe_shoe_id}/{user_user_id}/{purchase_id}/{store_store_id}")
def delete(
    shoe_shoe_id: str,
    user_user_id: str,
    purchase_id: str,
    store_store_id: str,
):
    return delete_purchase(shoe_shoe_id, user_user_id, purchase_id, store_store_id)
