from fastapi import APIRouter
from app.api.v1.auth import router as auth_router
from app.api.v1.dashboard import router as dashboard_router
from app.api.v1.resume import router as resume_router
from app.api.v1.jd_matcher import router as jd_matcher_router
from app.api.v1.follow_up import router as follow_up_router
from app.api.v1.roadmap import router as roadmap_router
from app.api.v1.jobs import router as jobs_router

api_router = APIRouter()
api_router.include_router(auth_router)
api_router.include_router(dashboard_router)
api_router.include_router(resume_router)
api_router.include_router(jd_matcher_router)
api_router.include_router(follow_up_router)
api_router.include_router(roadmap_router)
api_router.include_router(jobs_router)
