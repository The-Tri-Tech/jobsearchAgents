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
    avatar_letter = Column(String, default="S")
    phone_number = Column(String, default="+91 98765 43210")
    location = Column(String, default="Bengaluru, Karnataka, India")
    target_role = Column(String, default="Associate Product Manager")
    bio = Column(String, default="Aspiring Product & Tech Professional")
    created_at = Column(DateTime, default=datetime.utcnow)
