from fastapi import APIRouter, Depends
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
def get_dashboard_overview(current_user: User = Depends(get_current_user)):
    user_out = UserOut.model_validate(current_user)
    first_name = current_user.full_name.split()[0] if current_user.full_name else "Student"

    metrics = [
        StatCard(
            title="ATS Score",
            value="--",
            action_label="Upload resume to start",
            icon_type="person",
        ),
        StatCard(
            title="JD Match",
            value="--",
            action_label="Analyze a JD",
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
        ProgressItem(label="JD match rate", status="No data"),
        ProgressItem(label="Roadmap completion", status="No roadmap yet"),
        ProgressItem(label="Interview score", status="Not completed"),
    ]

    today_tasks = [
        TaskItem(id=1, title="Upload and parse resume", completed=False),
        TaskItem(id=2, title="Run ATS analysis", completed=False),
        TaskItem(id=3, title="Analyze JD match", completed=False),
        TaskItem(id=4, title="Generate roadmap", completed=False),
        TaskItem(id=5, title="Complete adaptive quiz", completed=False),
        TaskItem(id=6, title="Complete mock interview", completed=False),
        TaskItem(id=7, title="Save at least one job", completed=False),
    ]

    return DashboardOverview(
        greeting=f"Good morning, {first_name} ✦",
        subtitle="This view updates from your real resume, JD, roadmap, quiz, interview, and jobs activity.",
        user=user_out,
        metrics=metrics,
        weekly_progress=weekly_progress,
        today_tasks=today_tasks,
    )

