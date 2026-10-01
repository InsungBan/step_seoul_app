from decimal import Decimal

from fastapi import APIRouter, Form

from services.store_service import create_store, read_store, update_store, delete_store

router = APIRouter(prefix="/store", tags=["store"])


@router.post("/upload")
def upload(
    store_id: str = Form(..., max_length=20),
    latitude: Decimal | None = Form(None, max_digits=10, decimal_places=7),
    longitude: Decimal | None = Form(None, max_digits=10, decimal_places=7),
    district_name: str | None = Form(None, max_length=45),
    agency_name: str | None = Form(None, max_length=45),
    phone: str | None = Form(None, max_length=12),
):
    return create_store(store_id, latitude, longitude, district_name, agency_name, phone)


@router.get("/select")
def select():
    return read_store()


@router.put("/update/{store_id}")
def update(
    store_id: str,
    latitude: Decimal | None = Form(None, max_digits=10, decimal_places=7),
    longitude: Decimal | None = Form(None, max_digits=10, decimal_places=7),
    district_name: str | None = Form(None, max_length=45),
    agency_name: str | None = Form(None, max_length=45),
    phone: str | None = Form(None, max_length=12),
):
    return update_store(store_id, latitude, longitude, district_name, agency_name, phone)


@router.delete("/delete/{store_id}")
def delete(
    store_id: str,
):
    return delete_store(store_id)
