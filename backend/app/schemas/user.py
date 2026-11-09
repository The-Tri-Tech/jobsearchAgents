from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, EmailStr, Field
from app.schemas.follow_up import FollowUpOut
from app.schemas.reminder import ReminderOut

class UserBase(BaseModel):
    email: EmailStr
    full_name: Optional[str] = "Student"
    phone_number: Optional[str] = "+91 98765 43210"
    location: Optional[str] = "Bengaluru, Karnataka, India"
    target_role: Optional[str] = "Associate Product Manager"
    bio: Optional[str] = "Aspiring Product & Tech Professional"

class UserCreate(UserBase):
    password: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    phone_number: Optional[str] = None
    email: Optional[EmailStr] = None
    location: Optional[str] = None
    target_role: Optional[str] = None
    bio: Optional[str] = None

class UserOut(UserBase):
    id: int
    plan: str = "Pro plan"
    avatar_letter: str = "S"
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
    weekly_progress: List[ProgressItem] = Field(default_factory=list)
    reminders: List[ReminderOut] = Field(default_factory=list)
    today_tasks: List[TaskItem] = Field(default_factory=list)
    follow_ups: List[FollowUpOut] = Field(default_factory=list)
