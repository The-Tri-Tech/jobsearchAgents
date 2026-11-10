from pathlib import Path
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.jd_analysis import JdAnalysis
from app.models.user import User
from app.schemas.user import (
    DashboardOverview,
    StatCard,
    ProgressItem,
    TaskItem,
    UserOut,
)
from app.api.v1.auth import get_current_user

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])

UPLOAD_DIR = Path(__file__).resolve().parents[4] / "uploads" / "resumes"


@router.get("/overview", response_model=DashboardOverview)
def get_dashboard_overview(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    user_out = UserOut.model_validate(current_user)
    first_name = current_user.full_name.split()[0] if current_user.full_name else "Candidate"

    # Count uploaded resumes
    resume_count = 0
    if UPLOAD_DIR.exists():
        resume_count = len(
            [f for f in UPLOAD_DIR.iterdir() if f.is_file() and f.suffix.lower() in {".pdf", ".doc", ".docx"}]
        )

    # Calculate average JD match if any analyses exist
    jd_records = (
        db.query(JdAnalysis)
        .filter((JdAnalysis.user_id == current_user.id) | (JdAnalysis.user_id == None))
        .all()
    )
    if jd_records:
        avg_match = round(sum(r.match_score for r in jd_records) / len(jd_records))
        jd_match_str = f"{avg_match}%"
        jd_action = f"{len(jd_records)} analyzed"
    else:
        jd_match_str = "--"
        jd_action = "Analyze a JD"

    metrics = [
        StatCard(
            title="Resumes Uploaded",
            value=str(resume_count) if resume_count > 0 else "--",
            action_label="Upload resume" if resume_count == 0 else f"{resume_count} active",
            icon_type="document",
        ),
        StatCard(
            title="JD Match Rate",
            value=jd_match_str,
            action_label=jd_action,
            icon_type="target",
        ),
        StatCard(
            title="Career Roadmap",
            value="Phase 1",
            action_label="View milestones",
            icon_type="roadmap",
        ),
        StatCard(
            title="Jobs Tracked",
            value="4",
            action_label="Explore jobs",
            icon_type="briefcase",
        ),
    ]

    weekly_progress = [
        ProgressItem(label="Resume strength", status=f"{resume_count} uploaded" if resume_count > 0 else "Pending upload"),
        ProgressItem(label="JD match rate", status=jd_match_str if jd_records else "Ready to analyze"),
        ProgressItem(label="Roadmap completion", status="Phase 1 • 25% complete"),
        ProgressItem(label="Job applications", status="4 matched openings"),
    ]

    today_tasks = [
        TaskItem(id=1, title="Upload and parse your latest resume", completed=resume_count > 0),
        TaskItem(id=2, title="Run JD Matcher against a target job posting", completed=len(jd_records) > 0),
        TaskItem(id=3, title="Review Phase 1 core skills roadmap milestones", completed=False),
        TaskItem(id=4, title="Explore and track recommended jobs", completed=False),
    ]

    return DashboardOverview(
        greeting=f"Good morning, {first_name} ✦",
        subtitle="Your unified career dashboard — track resumes, JD match evaluations, roadmap progress, and jobs.",
        user=user_out,
        metrics=metrics,
        weekly_progress=weekly_progress,
        today_tasks=today_tasks,
    )
