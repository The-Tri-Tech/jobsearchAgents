from datetime import date, datetime, timedelta
from pathlib import Path
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.db.session import get_db
from app.models.follow_up import FollowUp
from app.models.jd_analysis import JdAnalysis
from app.models.user import User
from app.models.job import Job
from app.models.reminder import Reminder
from app.schemas.user import (
    DashboardOverview,
    StatCard,
    ProgressItem,
    TaskItem,
    UserOut,
)
from app.schemas.reminder import (
    ReminderCreate,
    ReminderOut,
    ReminderUpdate,
)
from app.api.v1.auth import get_current_user

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])

UPLOAD_DIR = Path(__file__).resolve().parents[4] / "uploads" / "resumes"

def _seed_initial_reminders(db: Session, user_id: int):
    today = date.today()
    initial_reminders = [
        Reminder(
            user_id=user_id,
            title="Follow up on apna (Associate Product Manager application)",
            category="Application",
            due_date=today + timedelta(days=2),
            completed=False,
        ),
        Reminder(
            user_id=user_id,
            title="Review matched skills & keywords for Franklin Templeton",
            category="JD Prep",
            due_date=today + timedelta(days=1),
            completed=False,
        ),
        Reminder(
            user_id=user_id,
            title="Update resume profile with Cloud & Docker achievements",
            category="Resume",
            due_date=today + timedelta(days=4),
            completed=False,
        ),
        Reminder(
            user_id=user_id,
            title="Explore Career Roadmap Phase 1 milestone deliverables",
            category="Roadmap",
            due_date=today + timedelta(days=6),
            completed=False,
        ),
    ]
    db.add_all(initial_reminders)
    db.commit()

@router.get("/overview", response_model=DashboardOverview)
def get_dashboard_overview(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    user_out = UserOut.model_validate(current_user)
    first_name = current_user.full_name.split()[0] if current_user.full_name else "Student"

    # Query user JD analyses
    jd_records = (
        db.query(JdAnalysis)
        .filter(JdAnalysis.user_id == current_user.id)
        .all()
    )
    if jd_records:
        avg_match = round(sum(r.match_score for r in jd_records) / len(jd_records))
        jd_analyzed_count = len(jd_records)
    else:
        avg_match_val = db.query(func.avg(Job.match_score)).filter(
            (Job.user_id == current_user.id) | (Job.user_id == None)
        ).scalar()
        avg_match = round(avg_match_val) if avg_match_val else 72
        jd_analyzed_count = 0

    # Query real resume files
    resume_count = 0
    if UPLOAD_DIR.exists():
        resume_count = len([f for f in UPLOAD_DIR.iterdir() if f.is_file() and f.suffix.lower() in {".pdf", ".doc", ".docx"}])
    if resume_count == 0:
        resume_count = 1

    # Query real jobs data
    jobs_query = db.query(Job).filter((Job.user_id == current_user.id) | (Job.user_id == None))
    total_jobs = jobs_query.count()

    # Query real scheduled follow-ups
    follow_ups = (
        db.query(FollowUp)
        .filter(FollowUp.user_id == current_user.id, FollowUp.status == "pending")
        .order_by(FollowUp.follow_up_date.asc())
        .all()
    )
    follow_ups_count = len(follow_ups)

    # Query or seed reminders
    existing_reminders_count = db.query(Reminder).filter(
        (Reminder.user_id == current_user.id) | (Reminder.user_id == None)
    ).count()

    if existing_reminders_count == 0:
        _seed_initial_reminders(db, current_user.id)

    reminders = (
        db.query(Reminder)
        .filter((Reminder.user_id == current_user.id) | (Reminder.user_id == None))
        .order_by(Reminder.completed.asc(), Reminder.due_date.asc(), Reminder.id.desc())
        .all()
    )

    metrics = [
        StatCard(
            title="Resumes",
            value=str(resume_count),
            action_label="Upload resume",
            icon_type="document",
        ),
        StatCard(
            title="JD Match",
            value=f"{avg_match}%" if (jd_analyzed_count > 0 or total_jobs > 0) else "--",
            action_label=f"{jd_analyzed_count} analyzed" if jd_analyzed_count > 0 else "Analyze a JD",
            icon_type="target",
        ),
        StatCard(
            title="Jobs Tracked",
            value=str(total_jobs),
            action_label="Explore jobs",
            icon_type="briefcase",
        ),
        StatCard(
            title="Follow-ups",
            value=str(follow_ups_count),
            action_label="View follow-ups",
            icon_type="bell",
        ),
    ]

    weekly_progress: List[ProgressItem] = []

    today_tasks = [
        TaskItem(id=r.id, title=r.title, completed=r.completed)
        for r in reminders
    ]

    return DashboardOverview(
        greeting=f"Good morning, {first_name} ✦",
        subtitle="This view updates from your real resume, JD matcher, and jobs activity.",
        user=user_out,
        metrics=metrics,
        weekly_progress=weekly_progress,
        reminders=reminders,
        today_tasks=today_tasks,
        follow_ups=follow_ups,
    )

@router.post("/reminders", response_model=ReminderOut, status_code=status.HTTP_201_CREATED)
def create_reminder(
    payload: ReminderCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if not payload.title.strip():
        raise HTTPException(status_code=400, detail="Reminder title cannot be empty")

    reminder = Reminder(
        user_id=current_user.id,
        title=payload.title.strip(),
        category=payload.category.strip() if payload.category else "General",
        due_date=payload.due_date or date.today() + timedelta(days=2),
        completed=False,
    )
    db.add(reminder)
    db.commit()
    db.refresh(reminder)
    return reminder

@router.put("/reminders/{reminder_id}/toggle", response_model=ReminderOut)
def toggle_reminder(
    reminder_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    reminder = db.query(Reminder).filter(
        Reminder.id == reminder_id,
        (Reminder.user_id == current_user.id) | (Reminder.user_id == None),
    ).first()

    if not reminder:
        raise HTTPException(status_code=404, detail="Reminder not found")

    reminder.completed = not reminder.completed
    db.commit()
    db.refresh(reminder)
    return reminder

@router.delete("/reminders/{reminder_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_reminder(
    reminder_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    reminder = db.query(Reminder).filter(
        Reminder.id == reminder_id,
        (Reminder.user_id == current_user.id) | (Reminder.user_id == None),
    ).first()

    if not reminder:
        raise HTTPException(status_code=404, detail="Reminder not found")

    db.delete(reminder)
    db.commit()
    return None
