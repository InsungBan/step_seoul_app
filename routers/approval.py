from fastapi import APIRouter, Form

from services.approval_service import create_approval, read_approval, update_approval, delete_approval

router = APIRouter(prefix="/approval", tags=["approval"])


@router.post("/upload")
def upload(
    approval_id: str = Form(..., max_length=20),
    approval_name: str | None = Form(None, max_length=45),
    approval_content: str | None = Form(None),
):
    return create_approval(approval_id, approval_name, approval_content)


@router.get("/select")
def select():
    return read_approval()


@router.put("/update/{approval_id}")
def update(
    approval_id: str,
    approval_name: str | None = Form(None, max_length=45),
    approval_content: str | None = Form(None),
):
    return update_approval(approval_id, approval_name, approval_content)


@router.delete("/delete/{approval_id}")
def delete(
    approval_id: str,
):
    return delete_approval(approval_id)
