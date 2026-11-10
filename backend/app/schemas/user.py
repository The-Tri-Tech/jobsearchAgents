from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, EmailStr

class UserBase(BaseModel):
    email: EmailStr
    full_name: Optional[str] = "Student"

class UserCreate(UserBase):
    password: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    email: Optional[EmailStr] = None

class UserOut(UserBase):
    id: int
    plan: str = "Pro plan"
    avatar_letter: str = "A"
    created_at: datetime

    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut

class StatCard(BaseModel):
    title: str
    value: str
    action_label: str
    icon_type: str

class ProgressItem(BaseModel):
    label: str
    status: str

class TaskItem(BaseModel):
    id: int
    title: str
    completed: bool = False

class DashboardOverview(BaseModel):
    greeting: str
    subtitle: str
    user: UserOut
    metrics: List[StatCard]
    weekly_progress: List[ProgressItem]
    today_tasks: List[TaskItem]
