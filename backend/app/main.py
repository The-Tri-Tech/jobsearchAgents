import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from app.core.config import settings
from app.db.session import engine, Base
from app.models import jd_analysis, user  # ensure models are registered
from app.api.v1.router import api_router

from sqlalchemy import inspect, text

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def _migrate_db(bind_engine):
    """Ensure newly added columns exist in existing SQLite tables."""
    try:
        inspector = inspect(bind_engine)
        with bind_engine.begin() as conn:
            if "users" in inspector.get_table_names():
                user_cols = {c["name"] for c in inspector.get_columns("users")}
                new_user_cols = {
                    "phone_number": "VARCHAR DEFAULT '+91 98765 43210'",
                    "location": "VARCHAR DEFAULT 'Bengaluru, Karnataka, India'",
                    "target_role": "VARCHAR DEFAULT 'Associate Product Manager'",
                    "bio": "VARCHAR DEFAULT 'Aspiring Product & Tech Professional'",
                    "plan": "VARCHAR DEFAULT 'Pro plan'",
                    "avatar_letter": "VARCHAR DEFAULT 'S'",
                }
                for col_name, col_def in new_user_cols.items():
                    if col_name not in user_cols:
                        conn.execute(text(f"ALTER TABLE users ADD COLUMN {col_name} {col_def}"))
            if "jd_analyses" in inspector.get_table_names():
                jd_cols = {c["name"] for c in inspector.get_columns("jd_analyses")}
                if "application_status" not in jd_cols:
                    conn.execute(text("ALTER TABLE jd_analyses ADD COLUMN application_status VARCHAR NOT NULL DEFAULT 'not_applied'"))
                if "applied_at" not in jd_cols:
                    conn.execute(text("ALTER TABLE jd_analyses ADD COLUMN applied_at DATETIME"))
    except Exception as err:
        logger.warning(f"Database schema check notice: {err}")

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Create tables on startup
    try:
        logger.info("Initializing database tables...")
        Base.metadata.create_all(bind=engine)
        _migrate_db(engine)
        logger.info("Database tables initialized successfully.")
    except Exception as e:
        logger.error(f"Error initializing database: {e}")
    yield

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    lifespan=lifespan,
)

# Enable CORS for Flutter Web / Desktop / Mobile
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix=settings.API_V1_STR)

@app.get("/health")
def health_check():
    return {"status": "ok", "app": settings.PROJECT_NAME}

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.exception("Unhandled server exception at %s: %s", request.url, exc)
    return JSONResponse(
        status_code=500,
        content={"detail": f"Internal server error: {str(exc)}"},
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
