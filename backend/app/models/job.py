from datetime import datetime
from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text
from app.db.session import Base

class Job(Base):
    __tablename__ = "jobs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True, index=True)
    title = Column(String, nullable=False)
    company = Column(String, nullable=True, default="Hiring Company")
    location = Column(String, nullable=True, default="Remote")
    job_url = Column(String, nullable=True)
    jd_text = Column(Text, nullable=True)
    match_score = Column(Integer, nullable=False, default=75)
    status = Column(String, nullable=False, default="Analyzed")  # Analyzed, Saved, Applied, Interviewing, Offer
    source = Column(String, nullable=False, default="JD Matcher") # JD Matcher, Link Import, Pasted JD
    tags = Column(String, nullable=True, default="")
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)

