import os
from pydantic_settings import BaseSettings
from typing import Literal, Optional

class Settings(BaseSettings):
    APP_ENV: Literal["development", "test", "production"] = "development"
    PROJECT_NAME: str = "SkillBridge API"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    # Database
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL",
        "sqlite:///./jobsearch.db"
    )
    
    # JWT & Auth
    SECRET_KEY: str = os.getenv("SECRET_KEY", "skillbridge_super_secret_jwt_key_2026_change_in_production")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days

    # Gemini job-matching agent
    LLM_PROVIDER: Literal["gemini", "openai"] = "gemini"
    GEMINI_API_KEY: Optional[str] = None
    GEMINI_MODEL: str = "gemini-3.8-flash"
    GEMINI_TIMEOUT_SECONDS: float = 180.0
    JOB_MATCH_TIMEOUT_SECONDS: float = 25.0

    # OpenAI job-matching agent
    OPENAI_API_KEY: Optional[str] = None
    OPENAI_MODEL: str = "gpt-5.5"
    OPENAI_TIMEOUT_SECONDS: float = 25.0

    class Config:
        case_sensitive = True
        env_file = ".env"
        extra = "allow"

settings = Settings()
