from typing import Literal
from pydantic import BaseModel, Field


class ChatMessageItem(BaseModel):
    role: Literal["user", "assistant"]
    content: str = Field(min_length=1, max_length=4000)


class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=2000)
    history: list[ChatMessageItem] = Field(default_factory=list, max_length=30)
    resume_filename: str | None = None


class ChatResponse(BaseModel):
    reply: str

