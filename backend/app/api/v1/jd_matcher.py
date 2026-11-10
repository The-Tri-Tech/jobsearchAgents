from datetime import datetime
import logging
import re
from typing import Optional
from urllib.parse import urlparse
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.v1.auth import get_current_user
from app.db.session import get_db
from app.api.v1.resume import UPLOAD_DIR, _safe_filename
from app.core.config import settings
from app.models.jd_analysis import JdAnalysis
from app.models.user import User
from app.schemas.jd_matcher import (
    AnalyseRequest,
    AnalysisReport,
    UpdateApplicationStatusRequest,
)
from app.services.job_matching_agent import (
    JobMatchingError,
    JobMatchingTimeoutError,
    fetch_job_description,
    job_matching_agent,
)
from app.services.groq_matching_agent import (
    GroqMatchingError,
    GroqMatchingTimeoutError,
    groq_matching_agent,
)
from app.services.resume_text import ResumeExtractionError, extract_resume_text
from app.services.mock_job_match import mock_job_match_report

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/jd-matcher", tags=["JD Matcher"])

BLOCKED_JOB_DOMAINS = {
    "indeed.com": "Indeed",
    "glassdoor.com": "Glassdoor",
    "naukri.com": "Naukri",
    "ziprecruiter.com": "ZipRecruiter",
}


def validate_jd_url(url: str) -> str:
    cleaned = url.strip()
    if not cleaned.startswith(("http://", "https://")):
        cleaned = "https://" + cleaned

    parsed = urlparse(cleaned)
    hostname = (parsed.hostname or "").lower()
    if not hostname or "." not in hostname:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Please provide a valid job posting URL (e.g. https://company.com/jobs/123).",
        )

    if "linkedin.com" in hostname:
        if not re.search(r"(\d{6,})", cleaned):
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Please provide a specific LinkedIn job posting URL (e.g. https://www.linkedin.com/jobs/view/1234567890).",
            )
        return cleaned

    for domain, site_name in BLOCKED_JOB_DOMAINS.items():
        if hostname == domain or hostname.endswith("." + domain):
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=(
                    f"{site_name} requires a user login to view job postings and blocks automated analysis. "
                    "Please copy the job description text and use 'Paste JD Text' instead."
                ),
            )
    return cleaned


@router.post("/analyse", response_model=AnalysisReport)
async def analyse_jd(
    payload: AnalyseRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    jd_text = (payload.jd_text or "").strip()
    jd_url = (payload.jd_url or "").strip()

    if not jd_text and not jd_url:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Provide either 'jd_text' or 'jd_url'.",
        )
    if not payload.resume_filename:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="'resume_filename' is required.",
        )

    safe_filename = _safe_filename(payload.resume_filename)
    resume_path = UPLOAD_DIR / safe_filename
    if not resume_path.is_file():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Resume file '{safe_filename}' not found.",
        )

    jd_source = "url" if jd_url else "text"
    if jd_url:
        jd_url = validate_jd_url(jd_url)

    if settings.APP_ENV == "development":
        report = mock_job_match_report(
            safe_filename,
            jd_source,
            target_job_title=payload.job_title,
            company=payload.company,
        )
        analysis_id = _persist_analysis(
            db,
            current_user,
            report,
            safe_filename,
            jd_source,
            jd_url=jd_url,
            job_description=payload.jd_text,
        )
        if analysis_id:
            report = report.model_copy(update={"analysis_id": analysis_id, "application_status": "not_applied"})
        return report

    # Production / Test mode: Extract text and invoke AI Agent
    try:
        resume_text = extract_resume_text(resume_path)
        job_description = await fetch_job_description(jd_url) if jd_url else jd_text

        if settings.LLM_PROVIDER == "groq":
            report = await groq_matching_agent.analyse(
                resume_text=resume_text,
                job_description=job_description,
                resume_filename=safe_filename,
                jd_source=jd_source,
            )
        else:
            report = await job_matching_agent.analyse(
                resume_text=resume_text,
                job_description=job_description,
                resume_filename=safe_filename,
                jd_source=jd_source,
            )

        analysis_id = _persist_analysis(
            db,
            current_user,
            report,
            safe_filename,
            jd_source,
            jd_url=jd_url,
            job_description=job_description,
        )
        if analysis_id:
            report = report.model_copy(update={"analysis_id": analysis_id, "application_status": "not_applied"})
        return report

    except (JobMatchingTimeoutError, GroqMatchingTimeoutError) as exc:
        raise HTTPException(
            status_code=status.HTTP_504_GATEWAY_TIMEOUT,
            detail=str(exc),
        ) from exc
    except ResumeExtractionError as exc:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(exc),
        ) from exc
    except (JobMatchingError, GroqMatchingError) as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=str(exc),
        ) from exc
    except Exception as exc:
        logger.exception("Unexpected error in Job Matching Agent: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"An unexpected error occurred during AI analysis: {str(exc)}",
        ) from exc


def _persist_analysis(
    db: Session,
    user: object,
    report: AnalysisReport,
    resume_filename: str,
    jd_source: str,
    jd_url: str | None = None,
    job_description: str | None = None,
) -> int | None:
    user_id = getattr(user, "id", None)
    if not user_id or not hasattr(db, "add"):
        return None
    try:
        role_title = (
            getattr(report, "target_job_title", None)
            or getattr(report, "job_title", None)
            or (report.recommended_roles[0].title if report.recommended_roles else "Target Job Role")
        )
        record = JdAnalysis(
            user_id=user_id,
            role_title=role_title,
            match_score=report.shortlisting_chance,
            overall_score=report.overall_score,
            resume_filename=resume_filename,
            jd_source=jd_source,
            application_status="not_applied",
        )
        db.add(record)

        # Auto-save analyzed job into Jobs table for real database sessions
        try:
            if hasattr(db, "query"):
                from app.models.job import Job
                clean_title = role_title
                clean_company = getattr(report, "company", None) or "Hiring Company"
                score = report.overall_score
                existing_job = None
                if jd_url:
                    existing_job = db.query(Job).filter(Job.job_url == jd_url).first()
                if not existing_job:
                    existing_job = db.query(Job).filter(Job.title == clean_title, Job.company == clean_company).first()
                if existing_job:
                    existing_job.match_score = score
                    existing_job.updated_at = datetime.utcnow()
                else:
                    new_job = Job(
                        user_id=user_id,
                        title=clean_title,
                        company=clean_company,
                        location="Remote",
                        job_url=jd_url if jd_url else None,
                        jd_text=(job_description or "")[:5000] if job_description else None,
                        match_score=score,
                        status="Analyzed",
                        source="Link Import" if jd_url else "JD Matcher",
                        tags="Resume Matched",
                    )
                    db.add(new_job)
        except Exception as job_exc:
            logger.warning("Could not auto-save job: %s", job_exc)

        if hasattr(db, "commit"):
            db.commit()
        if hasattr(db, "refresh"):
            db.refresh(record)
        return record.id
    except Exception as exc:
        logger.warning("Could not persist JD analysis: %s", exc)
        if hasattr(db, "rollback"):
            db.rollback()
        return None


@router.patch("/analysis/{analysis_id}/status", response_model=dict)
def update_analysis_status(
    analysis_id: int,
    payload: UpdateApplicationStatusRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    analysis = (
        db.query(JdAnalysis)
        .filter(JdAnalysis.id == analysis_id)
        .first()
    )
    if not analysis:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Analysis record not found.",
        )

    analysis.application_status = payload.application_status
    if payload.application_status == "applied":
        analysis.applied_at = datetime.utcnow()
        new_status = "Applied"
    else:
        analysis.applied_at = None
        new_status = "Not Applied"

    # Also sync with Job table
    try:
        from app.models.job import Job
        job = db.query(Job).filter(Job.title == analysis.role_title).order_by(Job.id.desc()).first()
        if job:
            job.status = new_status
            job.updated_at = datetime.utcnow()
    except Exception as e:
        logger.warning("Could not sync job status: %s", e)

    db.commit()
    db.refresh(analysis)
    return {
        "status": "success",
        "analysis_id": analysis.id,
        "application_status": analysis.application_status,
        "applied_at": analysis.applied_at.isoformat() if analysis.applied_at else None,
    }
