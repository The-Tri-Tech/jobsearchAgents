from datetime import date, datetime
from pydantic import BaseModel, ConfigDict, Field


class FollowUpCreate(BaseModel):
    report_title: str = Field(min_length=1, max_length=160)
    resume_filename: str = Field(min_length=1, max_length=255)
    application_date: date
    follow_up_after_days: int = Field(ge=1, le=365)


class FollowUpOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    report_title: str
    resume_filename: str
    application_date: date
    follow_up_after_days: int
    follow_up_date: date
    status: str
    created_at: datetime


class FollowUpList(BaseModel):
    follow_ups: list[FollowUpOut]
    count: int

