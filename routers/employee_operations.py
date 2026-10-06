from typing import Any

from fastapi import APIRouter, Query
from pydantic import BaseModel, Field

from services.employee_operations_service import read_state, write_state
from services.employee_service import read_employee
from services.purchase_service import read_purchase
from services.receive_service import read_receive
from services.return_record_service import read_return_record
from services.shipment_service import read_shipment
from services.shoe_service import read_shoe
from services.store_service import read_store
from services.user_service import read_user

router = APIRouter(prefix="/employee-operations", tags=["employee-operations"])


class StatePayload(BaseModel):
    scope_id: str = Field(default="step-pickup", min_length=1, max_length=45)
    state: dict[str, Any]


@router.get("/state")
def get_state(scope_id: str = Query(default="step-pickup", max_length=45)):
    return read_state(scope_id)


@router.put("/state")
def put_state(payload: StatePayload):
    return write_state(payload.scope_id, payload.state)


@router.get("/mysql-source")
def get_mysql_source():
    """Return employee source rows from the existing MySQL CRUD tables."""
    users = read_user()["result"]
    employees = read_employee()["result"]
    stores = read_store()["result"]
    return {
        "products": read_shoe()["result"],
        "shipments": read_shipment()["result"],
        "receipts": read_receive()["result"],
        "returns": read_return_record()["result"],
        "purchases": read_purchase()["result"],
        "users": [
            {key: row.get(key) for key in ("user_id", "user_name", "user_phone")}
            for row in users
        ],
        "employees": [
            {
                key: row.get(key)
                for key in ("employee_id", "employee_name", "employee_position", "employee_department")
            }
            for row in employees
        ],
        "stores": [
            {key: row.get(key) for key in ("store_id", "agency_name", "district_name", "phone")}
            for row in stores
        ],
    }
