from fastapi import APIRouter, Form

from services.approval_process_service import create_approval_process, read_approval_process, update_approval_process, delete_approval_process

router = APIRouter(prefix="/approval_process", tags=["approval_process"])


@router.post("/upload")
def upload(
    employee_employee_id: str = Form(..., max_length=20),
    approval_approval_id: str = Form(..., max_length=20),
    approval_process_id: str = Form(..., max_length=45),
    approval_date: str | None = Form(None, max_length=45),
    director_approval: str | None = Form(None, max_length=45),
    team_leader_approval: str | None = Form(None, max_length=45),
    approval_status: str | None = Form(None, max_length=45),
    processed_at: str | None = Form(None, max_length=45),
):
    return create_approval_process(employee_employee_id, approval_approval_id, approval_process_id, approval_date, director_approval, team_leader_approval, approval_status, processed_at)


@router.get("/select")
def select():
    return read_approval_process()


@router.put("/update/{employee_employee_id}/{approval_approval_id}/{approval_process_id}")
def update(
    employee_employee_id: str,
    approval_approval_id: str,
    approval_process_id: str,
    approval_date: str | None = Form(None, max_length=45),
    director_approval: str | None = Form(None, max_length=45),
    team_leader_approval: str | None = Form(None, max_length=45),
    approval_status: str | None = Form(None, max_length=45),
    processed_at: str | None = Form(None, max_length=45),
):
    return update_approval_process(employee_employee_id, approval_approval_id, approval_process_id, approval_date, director_approval, team_leader_approval, approval_status, processed_at)


@router.delete("/delete/{employee_employee_id}/{approval_approval_id}/{approval_process_id}")
def delete(
    employee_employee_id: str,
    approval_approval_id: str,
    approval_process_id: str,
):
    return delete_approval_process(employee_employee_id, approval_approval_id, approval_process_id)
