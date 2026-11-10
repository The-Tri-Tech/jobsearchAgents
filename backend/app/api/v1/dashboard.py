from datetime import date, datetime, timedelta
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.user import User
from app.models.jd_analysis import JdAnalysis
from app.models.job import Job
from app.models.follow_up import FollowUp
from app.models.reminder import Reminder
from app.api.v1.resume import UPLOAD_DIR
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
)
from app.api.v1.auth import get_current_user

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])


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

    # 1. Resumes count
    resume_files = [f for f in UPLOAD_DIR.iterdir() if f.is_file() and not f.name.startswith(".")] if UPLOAD_DIR.exists() else []
    resume_count = len(resume_files)

    # 2. Latest JD Match
    latest_analysis = (
        db.query(JdAnalysis)
        .order_by(JdAnalysis.created_at.desc())
        .first()
    )
    jd_match_val = f"{latest_analysis.match_score}%" if latest_analysis else "--"

    # 3. Tracked / Analyzed Jobs count
    jobs_count = db.query(Job).count()

    # 4. Pending Follow-ups
    follow_ups = (
        db.query(FollowUp)
        .filter(FollowUp.status == "pending")
        .order_by(FollowUp.follow_up_date.asc())
        .all()
    )

    # 5. Reminders
    existing_reminders_count = db.query(Reminder).count()
    if existing_reminders_count == 0:
        _seed_initial_reminders(db, current_user.id)

    reminders = (
        db.query(Reminder)
        .order_by(Reminder.completed.asc(), Reminder.due_date.asc(), Reminder.id.desc())
        .all()
    )

    metrics = [
        StatCard(
            title="Resumes",
            value=str(resume_count) if resume_count > 0 else "--",
            action_label="Upload resume",
            icon_type="document",
        ),
        StatCard(
            title="JD Match",
            value=jd_match_val,
            action_label="Analyze a JD",
            icon_type="target",
        ),
        StatCard(
            title="Jobs Tracked",
            value=str(jobs_count),
            action_label="Explore jobs",
            icon_type="briefcase",
        ),
        StatCard(
            title="Follow-ups",
            value=str(len(follow_ups)),
            action_label="View follow-ups",
            icon_type="calendar",
        ),
    ]

    weekly_progress = [
        ProgressItem(label="Resume uploaded", status=f"{resume_count} available" if resume_count > 0 else "Pending upload"),
        ProgressItem(label="JD match rate", status=jd_match_val if latest_analysis else "Not analyzed yet"),
        ProgressItem(label="Roadmap progress", status="Phase 1 In Progress"),
        ProgressItem(label="Analyzed jobs", status=f"{jobs_count} tracked"),
    ]

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
        today_tasks=today_tasks,
        follow_ups=follow_ups,
        reminders=reminders,
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
        due_date=payload.due_date or (date.today() + timedelta(days=2)),
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
    reminder = db.query(Reminder).filter(Reminder.id == reminder_id).first()
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
    reminder = db.query(Reminder).filter(Reminder.id == reminder_id).first()
    if not reminder:
        raise HTTPException(status_code=404, detail="Reminder not found")

    db.delete(reminder)
    db.commit()
    return None
