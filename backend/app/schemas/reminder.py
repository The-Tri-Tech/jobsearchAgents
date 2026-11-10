from datetime import date, datetime
from typing import Optional, List
from pydantic import BaseModel

class ReminderBase(BaseModel):
    title: str
    due_date: Optional[date] = None
    category: Optional[str] = "General"
    completed: bool = False

class ReminderCreate(BaseModel):
    title: str
    due_date: Optional[date] = None
    category: Optional[str] = "General"

class ReminderUpdate(BaseModel):
    title: Optional[str] = None
    due_date: Optional[date] = None
    category: Optional[str] = None
    completed: Optional[bool] = None

class ReminderOut(ReminderBase):
    id: int
    user_id: Optional[int] = None
    created_at: datetime

    class Config:
        from_attributes = True

class ReminderList(BaseModel):
    reminders: List[ReminderOut]
    count: int

