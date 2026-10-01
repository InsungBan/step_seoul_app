from fastapi import APIRouter, Form

from services.employee_service import create_employee, read_employee, update_employee, delete_employee

router = APIRouter(prefix="/employee", tags=["employee"])


@router.post("/upload")
def upload(
    employee_id: str = Form(..., max_length=20),
    employee_pw: str | None = Form(None, max_length=45),
    employee_position: str | None = Form(None, max_length=45),
    employee_name: str | None = Form(None, max_length=45),
    employee_department: str | None = Form(None, max_length=45),
):
    return create_employee(employee_id, employee_pw, employee_position, employee_name, employee_department)


@router.get("/select")
def select():
    return read_employee()


@router.put("/update/{employee_id}")
def update(
    employee_id: str,
    employee_pw: str | None = Form(None, max_length=45),
    employee_position: str | None = Form(None, max_length=45),
    employee_name: str | None = Form(None, max_length=45),
    employee_department: str | None = Form(None, max_length=45),
):
    return update_employee(employee_id, employee_pw, employee_position, employee_name, employee_department)


@router.delete("/delete/{employee_id}")
def delete(
    employee_id: str,
):
    return delete_employee(employee_id)
