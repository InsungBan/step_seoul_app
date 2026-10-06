import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers.hq import router as hq_router

from routers.approval import router as approval_router
from routers.approval_process import router as approval_process_router
from routers.authentication import router as authentication_router
from routers.cart import router as cart_router
from routers.checkout import router as checkout_router
from routers.employee import router as employee_router
from routers.employee_operations import router as employee_operations_router
from routers.get_order import router as get_order_router
from routers.manufacturing import router as manufacturing_router
from routers.payment import router as payment_router
from routers.purchase import router as purchase_router
from routers.purchase_order import router as purchase_order_router
from routers.recall import router as recall_router
from routers.receive import router as receive_router
from routers.refund import router as refund_router
from routers.return_record import router as return_record_router
from routers.shipment import router as shipment_router
from routers.shoe import router as shoe_router
from routers.shoe_manufacturer import router as shoe_manufacturer_router
from routers.store import router as store_router
from routers.user import router as user_router
from services.shoe_service import ensure_shoe_category_column

app = FastAPI(title="STEP SEOUL API", version="1.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def initialize_schema():
    ensure_shoe_category_column()

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=os.getenv("HQ_CORS_ORIGIN_REGEX", r"https?://(localhost|127\.0\.0\.1|192\.168\.10\.39)(:\d+)?"),
    allow_methods=["GET", "POST", "PUT"],
    allow_headers=["*"],
)
app.include_router(hq_router)
app.include_router(approval_router)
app.include_router(approval_process_router)
app.include_router(authentication_router)
app.include_router(cart_router)
app.include_router(checkout_router)
app.include_router(employee_router)
app.include_router(employee_operations_router)
app.include_router(get_order_router)
app.include_router(manufacturing_router)
app.include_router(payment_router)
app.include_router(purchase_router)
app.include_router(purchase_order_router)
app.include_router(recall_router)
app.include_router(receive_router)
app.include_router(refund_router)
app.include_router(return_record_router)
app.include_router(shipment_router)
app.include_router(shoe_router)
app.include_router(shoe_manufacturer_router)
app.include_router(store_router)
app.include_router(user_router)


@app.get("/")
def root():
    return {"status": "success", "message": "STEP SEOUL API가 실행 중입니다."}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "main:app",
        host=os.getenv("API_HOST", "0.0.0.0"),
        port=int(os.getenv("API_PORT", "8000")),
        reload=True,
    )
