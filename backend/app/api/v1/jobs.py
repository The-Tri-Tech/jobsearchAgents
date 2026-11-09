from datetime import datetime
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.v1.auth import get_optional_user
from app.db.session import get_db
from app.models.job import Job
from app.models.user import User
from app.schemas.job import JobCreate, JobList, JobOut, JobUpdate, JobUpdateStatus

router = APIRouter(prefix="/jobs", tags=["Jobs Explorer & Tracker"])

@router.get("", response_model=JobList)
def list_jobs(
    current_user: Optional[User] = Depends(get_optional_user),
    db: Session = Depends(get_db),
):
    query = db.query(Job)
    if current_user:
        query = query.filter((Job.user_id == current_user.id) | (Job.user_id.is_(None)))
    jobs = query.order_by(Job.created_at.desc()).all()
    return JobList(jobs=jobs, count=len(jobs))

@router.post("", response_model=JobOut, status_code=status.HTTP_201_CREATED)
def create_job(
    payload: JobCreate,
    current_user: Optional[User] = Depends(get_optional_user),
    db: Session = Depends(get_db),
):
    user_id = current_user.id if current_user else None
    clean_title = payload.title.strip() or "Tracked Job Opportunity"
    clean_company = (payload.company or "Target Company").strip()

    job = Job(
        user_id=user_id,
        title=clean_title,
        company=clean_company,
        location=(payload.location or "Remote").strip(),
        job_url=payload.job_url.strip() if payload.job_url else None,
        jd_text=payload.jd_text.strip() if payload.jd_text else None,
        match_score=payload.match_score if payload.match_score is not None else 78,
        status=payload.status or "Analyzed",
        source=payload.source or "JD Matcher",
        tags=payload.tags or "",
    )
    db.add(job)
    db.commit()
    db.refresh(job)
    return job

@router.patch("/{job_id}/status", response_model=JobOut)
def update_job_status(
    job_id: int,
    payload: JobUpdateStatus,
    db: Session = Depends(get_db),
):
    job = db.query(Job).filter(Job.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    job.status = payload.status
    job.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(job)
    return job

@router.put("/{job_id}", response_model=JobOut)
def update_job(
    job_id: int,
    payload: JobUpdate,
    db: Session = Depends(get_db),
):
    job = db.query(Job).filter(Job.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    if payload.title is not None and payload.title.strip():
        job.title = payload.title.strip()
    if payload.company is not None and payload.company.strip():
        job.company = payload.company.strip()
    if payload.location is not None and payload.location.strip():
        job.location = payload.location.strip()
    if payload.job_url is not None:
        job.job_url = payload.job_url.strip() if payload.job_url.strip() else None
    if payload.jd_text is not None:
        job.jd_text = payload.jd_text.strip() if payload.jd_text.strip() else None
    if payload.match_score is not None:
        job.match_score = payload.match_score
    if payload.status is not None:
        job.status = payload.status
    if payload.source is not None:
        job.source = payload.source
    if payload.tags is not None:
        job.tags = payload.tags
    job.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(job)
    return job

@router.delete("/{job_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_job(
    job_id: int,
    db: Session = Depends(get_db),
):
    job = db.query(Job).filter(Job.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    db.delete(job)
    db.commit()
    return None

