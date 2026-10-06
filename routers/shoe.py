from fastapi import APIRouter, Form, Query

from services.shoe_service import create_shoe, delete_shoe, read_shoe, search_shoe, update_shoe

router = APIRouter(prefix="/shoe", tags=["shoe"])


@router.post("/upload")
def upload(
    shoe_id: str = Form(..., max_length=45),
    brand_name: str | None = Form(None, max_length=45),
    shoe_category: str | None = Form(None, max_length=45),
    shoe_image_url: str | None = Form(None),
    shoe_price: str | None = Form(None, max_length=45),
    standard_stock: int | None = Form(None, ge=-2147483648, le=2147483647),
    stock_quantity: int | None = Form(None, ge=-2147483648, le=2147483647),
    manufacturer_name: str | None = Form(None, min_length=1, max_length=45),
    shoe_img_url: str | None = Form(None),
    shoe_name: str | None = Form(None, max_length=45),
):
    return create_shoe(
        shoe_id,
        brand_name,
        shoe_category,
        shoe_image_url,
        shoe_price,
        standard_stock,
        stock_quantity,
        shoe_img_url=shoe_img_url,
        shoe_name=shoe_name,
        manufacturer_name=manufacturer_name,
    )


@router.get("/search")
def search(
    query: str | None = Query(None, max_length=45),
    category: str | None = Query(None, max_length=45),
):
    return search_shoe(query, category)


@router.get("/select")
def select():
    return read_shoe()


@router.put("/update/{shoe_id}")
def update(
    shoe_id: str,
    brand_name: str | None = Form(None, max_length=45),
    shoe_category: str | None = Form(None, max_length=45),
    shoe_image_url: str | None = Form(None),
    shoe_price: str | None = Form(None, max_length=45),
    standard_stock: int | None = Form(None, ge=-2147483648, le=2147483647),
    stock_quantity: int | None = Form(None, ge=-2147483648, le=2147483647),
    shoe_img_url: str | None = Form(None),
    shoe_name: str | None = Form(None, max_length=45),
):
    return update_shoe(
        shoe_id,
        brand_name,
        shoe_category,
        shoe_image_url,
        shoe_price,
        standard_stock,
        stock_quantity,
        shoe_img_url=shoe_img_url,
        shoe_name=shoe_name,
    )


@router.delete("/delete/{shoe_id}")
def delete(
    shoe_id: str,
):
    return delete_shoe(shoe_id)
