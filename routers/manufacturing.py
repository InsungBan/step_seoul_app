from fastapi import APIRouter, Form

from services.manufacturing_service import create_manufacturing, read_manufacturing, update_manufacturing, delete_manufacturing

router = APIRouter(prefix="/manufacturing", tags=["manufacturing"])


@router.post("/upload")
def upload(
    shoe_shoe_id: str = Form(..., max_length=45),
    shoe_manufacturer_manufacturer_id: str = Form(..., max_length=20),
    manufacturing_id: str = Form(..., max_length=45),
    manufacturing_date: str | None = Form(None, max_length=45),
):
    return create_manufacturing(shoe_shoe_id, shoe_manufacturer_manufacturer_id, manufacturing_id, manufacturing_date)


@router.get("/select")
def select():
    return read_manufacturing()


@router.put("/update/{shoe_shoe_id}/{shoe_manufacturer_manufacturer_id}/{manufacturing_id}")
def update(
    shoe_shoe_id: str,
    shoe_manufacturer_manufacturer_id: str,
    manufacturing_id: str,
    manufacturing_date: str | None = Form(None, max_length=45),
):
    return update_manufacturing(shoe_shoe_id, shoe_manufacturer_manufacturer_id, manufacturing_id, manufacturing_date)


@router.delete("/delete/{shoe_shoe_id}/{shoe_manufacturer_manufacturer_id}/{manufacturing_id}")
def delete(
    shoe_shoe_id: str,
    shoe_manufacturer_manufacturer_id: str,
    manufacturing_id: str,
):
    return delete_manufacturing(shoe_shoe_id, shoe_manufacturer_manufacturer_id, manufacturing_id)
