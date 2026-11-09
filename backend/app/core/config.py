import os
from pathlib import Path
from pydantic_settings import BaseSettings
from typing import Literal, Optional

BACKEND_DIR = Path(__file__).resolve().parent.parent.parent
DEFAULT_DB_PATH = str(BACKEND_DIR / "jobsearch.db")

class Settings(BaseSettings):
    APP_ENV: Literal["development", "test", "production"] = "development"
    PROJECT_NAME: str = "SkillBridge API"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    # Database
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL",
        f"sqlite:///{DEFAULT_DB_PATH}"
    )
    
    # JWT & Auth
    SECRET_KEY: str = os.getenv("SECRET_KEY", "skillbridge_super_secret_jwt_key_2026_change_in_production")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days

    # LLM Provider: "gemini" | "groq"
    LLM_PROVIDER: Literal["gemini", "groq"] = "gemini"

    # Gemini job-matching agent
    GEMINI_API_KEY: Optional[str] = None
    GEMINI_MODEL: str = "gemini-3.8-flash"
    GEMINI_TIMEOUT_SECONDS: float = 180.0
    JOB_MATCH_TIMEOUT_SECONDS: float = 75.0

    # Groq job-matching agent
    GROQ_API_KEY: Optional[str] = None
    GROQ_MODEL: str = "openai/gpt-oss-120b"
    GROQ_TIMEOUT_SECONDS: float = 45.0

    class Config:
        case_sensitive = True
        env_file = (str(BACKEND_DIR / ".env"), ".env")
        extra = "allow"

settings = Settings()
