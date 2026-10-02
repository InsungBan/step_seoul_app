from pydantic import BaseModel, Field
from fastapi import APIRouter

from services.checkout_service import complete_checkout, read_order_detail

router = APIRouter(prefix="/checkout", tags=["checkout"])


class CheckoutItem(BaseModel):
    shoe_id: str = Field(min_length=1, max_length=20)
    quantity: int = Field(ge=1, le=100)


class CheckoutRequest(BaseModel):
    user_id: str = Field(min_length=1, max_length=12)
    store_id: str = Field(min_length=1, max_length=20)
    items: list[CheckoutItem] = Field(min_length=1)
    payment_method: str = Field(min_length=1, max_length=45)
    clear_cart: bool = False


@router.post("/complete")
def complete(payload: CheckoutRequest):
    return complete_checkout(
        user_id=payload.user_id,
        store_id=payload.store_id,
        items=[item.model_dump() for item in payload.items],
        payment_method=payload.payment_method,
        clear_cart=payload.clear_cart,
    )


@router.get("/order/{user_id}/{order_id}")
def order_detail(user_id: str, order_id: str):
    return read_order_detail(user_id, order_id)
