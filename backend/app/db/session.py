import logging
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker, Session
from app.core.config import settings

logger = logging.getLogger(__name__)

Base = declarative_base()

def get_engine():
    # Attempt to connect to configured Postgres DATABASE_URL
    if settings.DATABASE_URL and "postgresql" in settings.DATABASE_URL:
        try:
            pg_engine = create_engine(settings.DATABASE_URL, pool_pre_ping=True)
            with pg_engine.connect() as conn:
                pass
            logger.info("Connected successfully to PostgreSQL database.")
            return pg_engine
        except Exception as e:
            logger.warning(
                f"Could not connect to PostgreSQL: {e}. "
                "Falling back to local SQLite database (skillbridge.db)."
            )
    
    # Fallback to local SQLite database
    sqlite_url = "sqlite:///./skillbridge.db"
    return create_engine(sqlite_url, connect_args={"check_same_thread": False})

engine = get_engine()
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    db: Session = SessionLocal()
    try:
        yield db
    finally:
        db.close()
