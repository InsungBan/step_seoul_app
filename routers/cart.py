from fastapi import APIRouter, Form

from services.cart_service import create_cart, read_cart, read_cart_for_user, update_cart, delete_cart

router = APIRouter(prefix="/cart", tags=["cart"])


@router.post("/upload")
def upload(
    user_user_id: str = Form(..., max_length=12),
    shoe_shoe_id: str = Form(..., max_length=45),
    cart_id: str = Form(..., max_length=45),
    added_at: str | None = Form(None, max_length=45),
):
    return create_cart(user_user_id, shoe_shoe_id, cart_id, added_at)


@router.get("/select")
def select():
    return read_cart()


@router.get("/select/user/{user_id}")
def select_for_user(user_id: str):
    return read_cart_for_user(user_id)


@router.put("/update/{user_user_id}/{shoe_shoe_id}/{cart_id}")
def update(
    user_user_id: str,
    shoe_shoe_id: str,
    cart_id: str,
    added_at: str | None = Form(None, max_length=45),
):
    return update_cart(user_user_id, shoe_shoe_id, cart_id, added_at)


@router.delete("/delete/{user_user_id}/{shoe_shoe_id}/{cart_id}")
def delete(
    user_user_id: str,
    shoe_shoe_id: str,
    cart_id: str,
):
    return delete_cart(user_user_id, shoe_shoe_id, cart_id)
