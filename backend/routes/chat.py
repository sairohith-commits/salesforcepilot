"""POST /api/chat — receive a question, run the Claude agent, return results."""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, field_validator

from services.claude_service import ask_agent

router = APIRouter()


class ChatRequest(BaseModel):
    question: str

    @field_validator("question")
    @classmethod
    def question_not_empty(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("question cannot be empty")
        return v.strip()


class ChartDataset(BaseModel):
    label: str
    data: list[float]


class ChartData(BaseModel):
    type: str
    labels: list[str]
    datasets: list[ChartDataset]


class ChatResponse(BaseModel):
    summary: str
    data: list[dict]
    columns: list[str]
    chart_type: str
    chart_data: ChartData
    query_time_ms: int
    tool_used: bool
    record_count: int


@router.post("/chat", response_model=ChatResponse)
def chat(body: ChatRequest):
    try:
        result = ask_agent(body.question)
    except KeyError as exc:
        raise HTTPException(status_code=500, detail=f"Missing environment variable: {exc}")
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc))

    return ChatResponse(**result)
