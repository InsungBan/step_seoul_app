from typing import Any

from fastapi import APIRouter, Query
from pydantic import BaseModel, Field

from services.employee_operations_service import read_state, write_state

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
