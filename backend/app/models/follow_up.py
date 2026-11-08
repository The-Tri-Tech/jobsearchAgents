from datetime import date, datetime

from sqlalchemy import Column, Date, DateTime, ForeignKey, Integer, String

from app.db.session import Base


class FollowUp(Base):
    __tablename__ = "follow_ups"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    report_title = Column(String, nullable=False)
    resume_filename = Column(String, nullable=False)
    application_date = Column(Date, nullable=False)
    follow_up_after_days = Column(Integer, nullable=False)
    follow_up_date = Column(Date, nullable=False, index=True)
    status = Column(String, nullable=False, default="pending")
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
