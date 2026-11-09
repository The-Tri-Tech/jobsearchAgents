from datetime import datetime
from sqlalchemy import Column, DateTime, ForeignKey, Integer, String
from app.db.session import Base


class JdAnalysis(Base):
    __tablename__ = "jd_analyses"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    role_title = Column(String, nullable=False)
    company_name = Column(String, nullable=True)
    match_score = Column(Integer, nullable=False)  # shortlisting_chance or overall_score
    overall_score = Column(Integer, nullable=True)
    resume_filename = Column(String, nullable=False)
    jd_source = Column(String, nullable=False, default="text")
    application_status = Column(String, nullable=False, default="not_applied")
    applied_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)

