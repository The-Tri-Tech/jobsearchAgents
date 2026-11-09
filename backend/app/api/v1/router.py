from fastapi import APIRouter
from app.api.v1.auth import router as auth_router
from app.api.v1.dashboard import router as dashboard_router
from app.api.v1.resume import router as resume_router
from app.api.v1.jd_matcher import router as jd_matcher_router
from app.api.v1.follow_up import router as follow_up_router
from app.api.v1.chat import router as chat_router
from app.api.v1.jd_evaluation import router as jd_evaluation_router

api_router = APIRouter()
api_router.include_router(auth_router)
api_router.include_router(dashboard_router)
api_router.include_router(resume_router)
api_router.include_router(jd_matcher_router)
api_router.include_router(follow_up_router)
api_router.include_router(chat_router)
api_router.include_router(jd_evaluation_router)
