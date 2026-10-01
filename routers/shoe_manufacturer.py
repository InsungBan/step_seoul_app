from fastapi import APIRouter, Form

from services.shoe_manufacturer_service import create_shoe_manufacturer, read_shoe_manufacturer, update_shoe_manufacturer, delete_shoe_manufacturer

router = APIRouter(prefix="/shoe_manufacturer", tags=["shoe_manufacturer"])


@router.post("/upload")
def upload(
    manufacturer_id: str = Form(..., max_length=20),
    manufacturer_name: str | None = Form(None, max_length=45),
):
    return create_shoe_manufacturer(manufacturer_id, manufacturer_name)


@router.get("/select")
def select():
    return read_shoe_manufacturer()


@router.put("/update/{manufacturer_id}")
def update(
    manufacturer_id: str,
    manufacturer_name: str | None = Form(None, max_length=45),
):
    return update_shoe_manufacturer(manufacturer_id, manufacturer_name)


@router.delete("/delete/{manufacturer_id}")
def delete(
    manufacturer_id: str,
):
    return delete_shoe_manufacturer(manufacturer_id)
