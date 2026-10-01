from fastapi import APIRouter, Form

from services.recall_service import create_recall, read_recall, update_recall, delete_recall

router = APIRouter(prefix="/recall", tags=["recall"])


@router.post("/upload")
def upload(
    store_store_id: str = Form(..., max_length=20),
    user_user_id: str = Form(..., max_length=12),
    recall_id: str | None = Form(None, max_length=45),
    recall_date: str | None = Form(None, max_length=45),
    recall_quantity: int | None = Form(None, ge=-2147483648, le=2147483647),
    employee_employee_id: str = Form(..., max_length=20),
):
    return create_recall(store_store_id, user_user_id, recall_id, recall_date, recall_quantity, employee_employee_id)


@router.get("/select")
def select():
    return read_recall()


@router.put("/update/{store_store_id}/{user_user_id}/{employee_employee_id}")
def update(
    store_store_id: str,
    user_user_id: str,
    employee_employee_id: str,
    recall_id: str | None = Form(None, max_length=45),
    recall_date: str | None = Form(None, max_length=45),
    recall_quantity: int | None = Form(None, ge=-2147483648, le=2147483647),
):
    return update_recall(store_store_id, user_user_id, employee_employee_id, recall_id, recall_date, recall_quantity)


@router.delete("/delete/{store_store_id}/{user_user_id}/{employee_employee_id}")
def delete(
    store_store_id: str,
    user_user_id: str,
    employee_employee_id: str,
):
    return delete_recall(store_store_id, user_user_id, employee_employee_id)
