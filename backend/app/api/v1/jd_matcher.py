from fastapi import APIRouter, Depends, HTTPException, status

from app.api.v1.auth import get_current_user
from app.api.v1.resume import UPLOAD_DIR, _safe_filename
from app.core.config import settings
from app.models.user import User
from app.schemas.jd_matcher import AnalyseRequest, AnalysisReport
from app.services.job_matching_agent import (
    JobMatchingError,
    fetch_job_description,
    job_matching_agent,
)
from app.services.resume_text import ResumeExtractionError, extract_resume_text
from app.services.mock_job_match import mock_job_match_report

router = APIRouter(prefix="/jd-matcher", tags=["JD Matcher"])


@router.post("/analyse", response_model=AnalysisReport)
async def analyse_jd(
    payload: AnalyseRequest,
    current_user: User = Depends(get_current_user),
):
    jd_text = (payload.jd_text or "").strip()
    jd_url = (payload.jd_url or "").strip()
    if not jd_text and not jd_url:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Provide either 'jd_text' or 'jd_url'.",
        )
    if jd_text and jd_url:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Provide a job description or URL, not both.",
        )

    safe_filename = _safe_filename(payload.resume_filename)
    if safe_filename != payload.resume_filename:
        raise HTTPException(status_code=400, detail="Invalid resume filename.")
    resume_path = UPLOAD_DIR / safe_filename
    if not resume_path.is_file():
        raise HTTPException(status_code=404, detail="Selected resume was not found.")

    jd_source = "url" if jd_url else "text"
    if settings.APP_ENV == "development":
        return mock_job_match_report(safe_filename, jd_source)

    try:
        resume_text = extract_resume_text(resume_path)
        job_description = await fetch_job_description(jd_url) if jd_url else jd_text
        return await job_matching_agent.analyse(
            resume_text=resume_text,
            job_description=job_description,
            resume_filename=safe_filename,
            jd_source=jd_source,
        )
    except (ResumeExtractionError, JobMatchingError) as exc:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(exc),
        ) from exc
