from datetime import date, datetime
import logging
from sqlalchemy.orm import Session

from app.models.follow_up import FollowUp
from app.models.jd_analysis import JdAnalysis

logger = logging.getLogger(__name__)


def get_today_follow_ups(db: Session, user_id: int) -> dict:
    """Fetches jobs where follow-up is due today or overdue for the user."""
    today = date.today()
    pending = (
        db.query(FollowUp)
        .filter(
            FollowUp.user_id == user_id,
            FollowUp.status == "pending",
            FollowUp.follow_up_date <= today,
        )
        .order_by(FollowUp.follow_up_date.asc())
        .all()
    )

    jobs = [
        {
            "id": f.id,
            "role_title": f.report_title,
            "resume_filename": f.resume_filename,
            "application_date": f.application_date.isoformat(),
            "follow_up_date": f.follow_up_date.isoformat(),
            "is_due_today": f.follow_up_date == today,
            "days_overdue": max(0, (today - f.follow_up_date).days),
        }
        for f in pending
    ]

    return {
        "scope": "today",
        "count": len(jobs),
        "as_of_date": today.isoformat(),
        "jobs": jobs,
    }


def get_all_follow_ups(db: Session, user_id: int) -> dict:
    """Fetches all pending job follow-ups for the user across all dates (past, today, future)."""
    today = date.today()
    pending = (
        db.query(FollowUp)
        .filter(
            FollowUp.user_id == user_id,
            FollowUp.status == "pending",
        )
        .order_by(FollowUp.follow_up_date.asc())
        .all()
    )

    jobs = [
        {
            "id": f.id,
            "role_title": f.report_title,
            "resume_filename": f.resume_filename,
            "application_date": f.application_date.isoformat(),
            "follow_up_date": f.follow_up_date.isoformat(),
            "is_due_today": f.follow_up_date == today,
            "days_until_follow_up": (f.follow_up_date - today).days,
            "status": f.status,
        }
        for f in pending
    ]

    return {
        "scope": "all",
        "count": len(jobs),
        "as_of_date": today.isoformat(),
        "jobs": jobs,
    }


def get_high_match_jobs(db: Session, user_id: int, min_score: int = 50) -> dict:
    """Fetches job descriptions analyzed where the match score is greater than min_score (default 50%)."""
    # Query JdAnalysis
    records = (
        db.query(JdAnalysis)
        .filter(
            JdAnalysis.user_id == user_id,
            JdAnalysis.match_score > min_score,
        )
        .order_by(JdAnalysis.match_score.desc())
        .all()
    )

    jobs = [
        {
            "id": r.id,
            "role_title": r.role_title,
            "match_score": r.match_score,
            "overall_score": r.overall_score or r.match_score,
            "resume_filename": r.resume_filename,
            "analyzed_at": r.created_at.strftime("%Y-%m-%d"),
        }
        for r in records
    ]

    return {
        "min_score": min_score,
        "count": len(jobs),
        "jobs": jobs,
    }


def get_overall_standing(db: Session, user_id: int) -> dict:
    """Calculates average score across all analyzed JDs and aggregates standing metrics."""
    records = (
        db.query(JdAnalysis)
        .filter(JdAnalysis.user_id == user_id)
        .order_by(JdAnalysis.created_at.desc())
        .all()
    )

    total_analyzed = len(records)
    scores = [r.match_score for r in records]
    avg_score = round(sum(scores) / total_analyzed, 1) if total_analyzed > 0 else 0.0
    highest_score = max(scores) if total_analyzed > 0 else 0
    lowest_score = min(scores) if total_analyzed > 0 else 0
    above_50 = sum(1 for s in scores if s > 50)

    pending_follow_ups = (
        db.query(FollowUp)
        .filter(FollowUp.user_id == user_id, FollowUp.status == "pending")
        .count()
    )

    return {
        "total_analyzed": total_analyzed,
        "average_score": avg_score,
        "highest_score": highest_score,
        "lowest_score": lowest_score,
        "jobs_above_50_percent": above_50,
        "pending_follow_ups": pending_follow_ups,
    }


def get_today_applied_jobs(db: Session, user_id: int) -> dict:
    """Fetches jobs that the user applied to today (from JD analyses marked 'applied' or scheduled follow-ups)."""
    today = date.today()
    applied_jobs = []
    seen_titles = set()

    # 1. From JdAnalysis where application_status == 'applied'
    analyses = (
        db.query(JdAnalysis)
        .filter(
            JdAnalysis.user_id == user_id,
            JdAnalysis.application_status == "applied",
        )
        .order_by(JdAnalysis.created_at.desc())
        .all()
    )

    for a in analyses:
        applied_date = (a.applied_at or a.created_at).date()
        if applied_date == today:
            applied_jobs.append({
                "id": a.id,
                "role_title": a.role_title,
                "resume_filename": a.resume_filename,
                "match_score": a.match_score,
                "applied_date": applied_date.isoformat(),
                "status": "applied",
            })
            seen_titles.add(a.role_title.strip().lower())

    # 2. Also check FollowUp applications recorded today
    follow_ups = (
        db.query(FollowUp)
        .filter(
            FollowUp.user_id == user_id,
            FollowUp.application_date == today,
        )
        .all()
    )
    for f in follow_ups:
        title_norm = f.report_title.strip().lower()
        if title_norm not in seen_titles:
            applied_jobs.append({
                "id": f.id,
                "role_title": f.report_title,
                "resume_filename": f.resume_filename,
                "match_score": None,
                "applied_date": f.application_date.isoformat(),
                "status": "applied",
            })
            seen_titles.add(title_norm)

    return {
        "count": len(applied_jobs),
        "as_of_date": today.isoformat(),
        "jobs": applied_jobs,
    }


def execute_career_tool(
    tool_name: str,
    arguments: dict,
    db: Session,
    user_id: int,
) -> dict:
    """Executes the given career MCP tool and returns a structured dictionary result."""
    if tool_name == "get_today_follow_ups":
        return get_today_follow_ups(db, user_id)
    elif tool_name == "get_all_follow_ups":
        return get_all_follow_ups(db, user_id)
    elif tool_name == "get_high_match_jobs":
        min_score = arguments.get("min_score", 50)
        return get_high_match_jobs(db, user_id, min_score=min_score)
    elif tool_name == "get_overall_standing":
        return get_overall_standing(db, user_id)
    elif tool_name == "get_today_applied_jobs":
        return get_today_applied_jobs(db, user_id)
    else:
        return {"error": f"Unknown tool '{tool_name}'"}


CAREER_TOOLS_SCHEMA = [
    {
        "type": "function",
        "function": {
            "name": "get_today_applied_jobs",
            "description": "Fetch the number and detailed list of jobs the user applied to today.",
            "parameters": {
                "type": "object",
                "properties": {},
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_today_follow_ups",
            "description": "Fetch job applications that the user needs to follow up on today.",
            "parameters": {
                "type": "object",
                "properties": {},
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_all_follow_ups",
            "description": "Fetch the full list of all scheduled job follow-ups for the user across all dates (past, today, and future).",
            "parameters": {
                "type": "object",
                "properties": {},
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_high_match_jobs",
            "description": "Fetch job descriptions analyzed by the user where their profile match score is greater than 50% (or specified min_score).",
            "parameters": {
                "type": "object",
                "properties": {
                    "min_score": {
                        "type": "integer",
                        "description": "Minimum match score threshold (default 50)",
                        "default": 50,
                    }
                },
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_overall_standing",
            "description": "Calculate average match score across all analyzed job descriptions and fetch overall performance & application metrics.",
            "parameters": {
                "type": "object",
                "properties": {},
            },
        },
    },
]

