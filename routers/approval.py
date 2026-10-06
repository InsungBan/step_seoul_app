from fastapi import APIRouter, Form
from pydantic import BaseModel, Field
from decimal import Decimal
from services.approval_service import submit_approval

from services.approval_service import create_approval, read_approval, update_approval, delete_approval

router = APIRouter(prefix="/approval", tags=["approval"])


class ProposalSubmission(BaseModel):
    approval_name: str = Field(min_length=1, max_length=45, pattern=r'\S')
    approval_content: str = Field(min_length=1, pattern=r'\S')
    employee_employee_id: str = Field(min_length=1, max_length=20, pattern=r'\S')
    requested_amount: Decimal = Field(ge=0, max_digits=18, decimal_places=2)


@router.post('/submit')
def submit(payload: ProposalSubmission):
    return submit_approval(payload.approval_name.strip(), payload.approval_content.strip(),
                           payload.employee_employee_id, payload.requested_amount)


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
