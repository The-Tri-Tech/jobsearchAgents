from datetime import datetime, date
from sqlalchemy import Column, Integer, String, Boolean, Date, DateTime, ForeignKey
from app.db.session import Base

class Reminder(Base):
    __tablename__ = "reminders"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True, index=True)
    title = Column(String, nullable=False)
    due_date = Column(Date, nullable=True)
    category = Column(String, nullable=False, default="General")  # Application, JD Prep, Resume, Roadmap, General
    completed = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)

