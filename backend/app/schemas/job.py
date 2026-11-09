from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel

class JobCreate(BaseModel):
    title: str
    company: Optional[str] = "Hiring Company"
    location: Optional[str] = "Remote"
    job_url: Optional[str] = None
    jd_text: Optional[str] = None
    match_score: Optional[int] = 75
    status: Optional[str] = "Analyzed"
    source: Optional[str] = "JD Matcher"
    tags: Optional[str] = ""

class JobUpdateStatus(BaseModel):
    status: str

class JobUpdate(BaseModel):
    title: Optional[str] = None
    company: Optional[str] = None
    location: Optional[str] = None
    job_url: Optional[str] = None
    jd_text: Optional[str] = None
    match_score: Optional[int] = None
    status: Optional[str] = None
    source: Optional[str] = None
    tags: Optional[str] = None

class JobOut(BaseModel):
    id: int
    user_id: Optional[int] = None
    title: str
    company: Optional[str] = "Hiring Company"
    location: Optional[str] = "Remote"
    job_url: Optional[str] = None
    jd_text: Optional[str] = None
    match_score: int = 75
    status: str = "Analyzed"
    source: str = "JD Matcher"
    tags: Optional[str] = ""
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class JobList(BaseModel):
    jobs: List[JobOut]
    count: int

