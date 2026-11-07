from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime
from app.db.session import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    full_name = Column(String, default="Student", nullable=False)
    hashed_password = Column(String, nullable=False)
    plan = Column(String, default="Pro plan")
    avatar_letter = Column(String, default="A")
    created_at = Column(DateTime, default=datetime.utcnow)

