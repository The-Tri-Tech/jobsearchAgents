from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.models.follow_up import FollowUp
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
        avg_score = round(sum(r.match_score for r in jd_records) / len(jd_records))
        jd_match_value = f"{avg_score}%"
        jd_match_label = f"{len(jd_records)} JD{'s' if len(jd_records) > 1 else ''} analyzed"
        jd_progress_status = f"{avg_score}% avg match"
        jd_analyzed_completed = True
    else:
        jd_match_value = "--"
        jd_match_label = "Analyze a JD"
        jd_progress_status = "No data"
        jd_analyzed_completed = False

    metrics = [
        StatCard(
            title="ATS Score",
            value="--",
            action_label="Upload resume to start",
            icon_type="person",
        ),
        StatCard(
            title="JD Match",
            value=jd_match_value,
            action_label=jd_match_label,
            icon_type="target",
        ),
        StatCard(
            title="Quiz Score",
            value="--",
            action_label="Complete a quiz",
            icon_type="lightning",
        ),
        StatCard(
            title="Jobs Saved",
            value="0",
            action_label="Search jobs to populate",
            icon_type="briefcase",
        ),
    ]

    weekly_progress = [
        ProgressItem(label="Resume strength", status="No data"),
        ProgressItem(label="JD match rate", status=jd_progress_status),
        ProgressItem(label="Roadmap completion", status="No roadmap yet"),
        ProgressItem(label="Interview score", status="Not completed"),
    ]

    today_tasks = [
        TaskItem(id=1, title="Upload and parse resume", completed=False),
        TaskItem(id=2, title="Run ATS analysis", completed=False),
        TaskItem(id=3, title="Analyze JD match", completed=jd_analyzed_completed),
        TaskItem(id=4, title="Generate roadmap", completed=False),
        TaskItem(id=5, title="Complete adaptive quiz", completed=False),
        TaskItem(id=6, title="Complete mock interview", completed=False),
        TaskItem(id=7, title="Save at least one job", completed=False),
    ]

    follow_ups = (
        db.query(FollowUp)
        .filter(FollowUp.user_id == current_user.id, FollowUp.status == "pending")
        .order_by(FollowUp.follow_up_date.asc())
        .all()
    )

    return DashboardOverview(
        greeting=f"Good morning, {first_name} ✦",
        subtitle="This view updates from your real resume, JD, roadmap, quiz, interview, and jobs activity.",
        user=user_out,
        metrics=metrics,
        weekly_progress=weekly_progress,
        today_tasks=today_tasks,
        follow_ups=follow_ups,
    )
