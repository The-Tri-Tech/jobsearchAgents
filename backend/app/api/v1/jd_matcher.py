from datetime import datetime
import logging
import re
from typing import Optional
from urllib.parse import urlparse
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.v1.auth import get_current_user, get_optional_user
from app.db.session import get_db
from app.models.job import Job
from app.api.v1.resume import UPLOAD_DIR, _safe_filename
from app.core.config import settings
from app.db.session import get_db
from app.models.jd_analysis import JdAnalysis
from app.models.user import User

logger = logging.getLogger(__name__)
from app.schemas.jd_matcher import AnalyseRequest, AnalysisReport, UpdateApplicationStatusRequest
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


def extract_job_details(
    jd_text: str = "",
    jd_url: str = "",
    pref_title: Optional[str] = None,
    pref_company: Optional[str] = None,
) -> tuple[str, str, str]:
    """Accurately extracts real job title, company, and location from URL and/or JD text."""
    title = (pref_title or "").strip()
    company = (pref_company or "").strip()
    location = "Remote"

    if jd_text:
        # Check standard LinkedIn / job board header: "Role at Company — Location"
        first_chunk = jd_text[:400]
        m_at_comp = re.search(
            r'([A-Za-z0-9 /&()\-]{3,50})\s+(?:at|@)\s+([A-Za-z0-9 &.,\'-]{2,30})(?:\s*[—\-|•,]\s*([A-Za-z0-9 ,.\'-]{2,40}))?',
            first_chunk,
            re.IGNORECASE,
        )
        if m_at_comp:
            if not title:
                title = m_at_comp.group(1).strip()
            if not company:
                company = m_at_comp.group(2).strip()
            if m_at_comp.group(3):
                location = m_at_comp.group(3).strip()

    if not company and jd_url:
        try:
            parsed = urlparse(jd_url)
            host = (parsed.hostname or "").lower()
            segments = [s for s in parsed.path.strip("/").split("/") if s]
            if "linkedin.com" in host:
                for seg in segments:
                    if "-at-" in seg.lower():
                        c = seg.split("-at-")[-1].split("-")[0]
                        if c and not c.isdigit():
                            company = c.replace("-", " ").title()
            elif "greenhouse.io" in host and segments:
                company = segments[0].replace("-", " ").title()
            elif "lever.co" in host and segments:
                company = segments[0].replace("-", " ").title()
            elif "ashbyhq.com" in host and segments:
                company = segments[0].replace("-", " ").title()
            elif "amazon.jobs" in host or "amazon" in host:
                company = "Amazon"
            elif "google" in host:
                company = "Google"
            elif "microsoft" in host:
                company = "Microsoft"
            elif "apple" in host:
                company = "Apple"
            elif "meta" in host:
                company = "Meta"
            elif "netflix" in host:
                company = "Netflix"
            elif "uber" in host:
                company = "Uber"
            else:
                parts = [p for p in host.split(".") if p not in {"www", "careers", "jobs", "job", "career", "com", "io", "co", "org", "net", "ai"}]
                if parts:
                    company = parts[0].title()
        except Exception:
            pass

    if not title and jd_url:
        try:
            parsed = urlparse(jd_url)
            segments = [s for s in parsed.path.strip("/").split("/") if s]
            for seg in reversed(segments):
                clean_seg = re.sub(r'-\d+$', '', seg)
                clean_seg = re.sub(r'^\d+-', '', clean_seg)
                if "-at-" in clean_seg.lower():
                    clean_seg = clean_seg.split("-at-")[0]
                if len(clean_seg) > 3 and not clean_seg.isdigit() and clean_seg.lower() not in {"jobs", "view", "job", "careers", "details", "results", "en", "us"}:
                    words = clean_seg.replace("-", " ").replace("_", " ").title()
                    if any(w in words.lower() for w in ["developer", "engineer", "manager", "lead", "analyst", "architect", "designer", "scientist", "intern", "specialist"]):
                        title = words
                        break
                    elif not title:
                        title = words
        except Exception:
            pass

    if jd_text:
        lines = [l.strip() for l in jd_text.splitlines() if l.strip()]
        if not company:
            for l in lines[:12]:
                m = re.search(r'^(?:Company|Organization|Employer)\s*:\s*([A-Za-z0-9 &.,\'-]{2,40})', l, re.IGNORECASE)
                if m:
                    company = m.group(1).strip()
                    break
                m2 = re.search(r'^(?:About|Join|Welcome to)\s+([A-Z][A-Za-z0-9 &.,\'-]{1,30})', l)
                if m2 and not any(w in m2.group(1).lower() for w in ["us", "our", "the role", "this job", "the team"]):
                    company = m2.group(1).strip()
                    break
                m3 = re.search(r'^At\s+([A-Z][A-Za-z0-9 &.,\'-]{1,30}),', l)
                if m3:
                    company = m3.group(1).strip()
                    break

        if not title:
            for l in lines[:12]:
                m = re.search(r'^(?:Job\s*Title|Position|Role|Title)\s*:\s*([A-Za-z0-9 /&()\-]{3,60})', l, re.IGNORECASE)
                if m:
                    title = m.group(1).strip()
                    break

            if not title:
                role_keywords = [
                    "developer", "engineer", "lead", "architect", "manager",
                    "analyst", "designer", "scientist", "intern", "specialist",
                    "administrator", "consultant", "programmer", "technician"
                ]
                for l in lines[:8]:
                    cleaned = re.sub(r'^[#*\-•\d.]+\s*', '', l).strip()
                    if 4 <= len(cleaned) <= 65 and any(k in cleaned.lower() for k in role_keywords):
                        if not cleaned.lower().startswith(("we are", "looking for", "requirements", "responsibilities", "you will")):
                            title = cleaned
                            break

        if not title and lines:
            first = re.sub(r'^[#*\-•\d.]+\s*', '', lines[0]).strip()
            if 4 <= len(first) <= 50 and not first.lower().startswith(("http", "www", "about", "we ")):
                title = first

    if not title:
        title = "Job Opportunity"
    if not company:
        company = "Hiring Company"

    return title, company, location


@router.post("/analyse", response_model=AnalysisReport)
async def analyse_jd(
    payload: AnalyseRequest,
    current_user: Optional[User] = Depends(get_optional_user),
    db: Session = Depends(get_db),
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
    if jd_url:
        jd_url = validate_jd_url(jd_url)

    safe_filename = _safe_filename(payload.resume_filename)
    if safe_filename != payload.resume_filename:
        raise HTTPException(status_code=400, detail="Invalid resume filename.")
    resume_path = UPLOAD_DIR / safe_filename
    if not resume_path.is_file():
        raise HTTPException(status_code=404, detail="Selected resume was not found.")

    # Accurately resolve job title and company from user input, URL, and text
    job_description = ""
    if jd_url:
        try:
            job_description = await fetch_job_description(jd_url)
        except Exception as e:
            if settings.APP_ENV != "development":
                raise e
    else:
        job_description = jd_text

    extracted_title, extracted_company, extracted_location = extract_job_details(
        jd_text=job_description or jd_text,
        jd_url=jd_url,
        pref_title=payload.job_title,
        pref_company=payload.company,
    )

    jd_source = "url" if jd_url else "text"
    if settings.APP_ENV == "development":
        report = mock_job_match_report(
            safe_filename,
            jd_source,
            target_job_title=extracted_title,
            company=extracted_company,
        )
        if extracted_title and extracted_title != "Job Opportunity":
            report.job_title = extracted_title
        analysis_id = _persist_analysis(db, current_user, report, safe_filename, jd_source)
        if analysis_id:
            report = report.model_copy(update={"analysis_id": analysis_id, "application_status": "not_applied"})
    else:
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
            report.target_job_title = extracted_title
            report.company = extracted_company
            if extracted_title and extracted_title != "Job Opportunity":
                report.job_title = extracted_title
            analysis_id = _persist_analysis(db, current_user, report, safe_filename, jd_source)
            if analysis_id:
                report = report.model_copy(update={"analysis_id": analysis_id, "application_status": "not_applied"})
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
            logger.exception("Unexpected error analyzing JD: %s", exc)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"An unexpected error occurred during analysis: {str(exc)}",
            ) from exc

    # Auto-save job into the Jobs database table with the real title and company
    try:
        score = getattr(report, "overall_score", 78)
        # Avoid duplicate row if this exact URL or title+company was just analyzed
        existing = None
        if jd_url:
            existing = db.query(Job).filter(Job.job_url == jd_url).first()
        if not existing:
            existing = db.query(Job).filter(Job.title == extracted_title, Job.company == extracted_company).first()

        if existing:
            existing.match_score = score
            existing.status = "Analyzed"
            existing.updated_at = datetime.utcnow()
            db.commit()
            db.refresh(existing)
        else:
            new_job = Job(
                user_id=current_user.id if current_user else None,
                title=extracted_title,
                company=extracted_company,
                location=extracted_location,
                job_url=jd_url if jd_url else None,
                jd_text=(job_description or jd_text)[:2000] if (job_description or jd_text) else None,
                match_score=score,
                status="Analyzed",
                source="Link Import" if jd_url else "Pasted JD",
                tags="Resume Matched, Verified",
            )
            db.add(new_job)
            db.commit()
    except Exception as e:
        logger.warning(f"Could not auto-save analyzed job: {e}")

    return report


def _persist_analysis(
    db: Session | None,
    user: object | None,
    report: AnalysisReport,
    resume_filename: str,
    jd_source: str,
) -> int | None:
    user_id = getattr(user, "id", None)
    if not user_id or not hasattr(db, "add"):
        return None
    try:
        extracted_title = (
            getattr(report, "target_job_title", None)
            or getattr(report, "job_title", None)
            or ""
        ).strip()
        role_title = (
            extracted_title
            if extracted_title and extracted_title not in ("Target Role", "Job Opportunity")
            else (
                report.recommended_roles[0].title
                if report.recommended_roles
                else "Target Job Role"
            )
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
        db.commit()
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
        .filter(JdAnalysis.id == analysis_id, JdAnalysis.user_id == current_user.id)
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
    else:
        analysis.applied_at = None

    db.commit()
    db.refresh(analysis)
    return {
        "status": "success",
        "analysis_id": analysis.id,
        "application_status": analysis.application_status,
        "applied_at": analysis.applied_at.isoformat() if analysis.applied_at else None,
    }
