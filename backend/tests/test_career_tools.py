from datetime import date, timedelta
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.db.session import Base
from app.models.follow_up import FollowUp
from app.models.jd_analysis import JdAnalysis
from app.models.user import User
from app.services.career_tools import (
    execute_career_tool,
    get_all_follow_ups,
    get_high_match_jobs,
    get_overall_standing,
    get_today_applied_jobs,
    get_today_follow_ups,
)
from app.services.chat_agent import check_career_guardrails


@pytest.fixture
def db_session():
    engine = create_engine("sqlite:///:memory:", connect_args={"check_same_thread": False})
    Base.metadata.create_all(bind=engine)
    Session = sessionmaker(bind=engine)
    session = Session()

    # Create dummy user
    test_user = User(
        id=1,
        full_name="Test User",
        email="test@example.com",
        hashed_password="hash",
    )
    session.add(test_user)
    session.commit()

    yield session
    session.close()


def test_guardrails_blocks_off_topic_queries():
    assert check_career_guardrails("Give me a recipe for chocolate cake") is not None
    assert check_career_guardrails("Who won the 2022 World Cup in football?") is not None
    assert check_career_guardrails("Tell me a funny joke about cats") is not None


def test_guardrails_allows_career_queries():
    assert check_career_guardrails("Hi, how are you?") is None
    assert check_career_guardrails("Today how many jobs I need to follow up?") is None
    assert check_career_guardrails("How many I applied where does it suit me score greater than 50%?") is None
    assert check_career_guardrails("How I am doing overall?") is None
    assert check_career_guardrails("Tips for software engineering interview") is None


def test_get_today_follow_ups(db_session):
    today = date.today()
    f1 = FollowUp(
        user_id=1,
        report_title="Stripe Backend Engineer",
        resume_filename="resume.pdf",
        application_date=today - timedelta(days=5),
        follow_up_after_days=5,
        follow_up_date=today,
        status="pending",
    )
    f2 = FollowUp(
        user_id=1,
        report_title="Google SRE",
        resume_filename="resume.pdf",
        application_date=today - timedelta(days=1),
        follow_up_after_days=7,
        follow_up_date=today + timedelta(days=6),  # Not due today
        status="pending",
    )
    db_session.add_all([f1, f2])
    db_session.commit()

    result = get_today_follow_ups(db_session, user_id=1)
    assert result["count"] == 1
    assert result["jobs"][0]["role_title"] == "Stripe Backend Engineer"

    # All follow-ups should return both jobs
    all_res = get_all_follow_ups(db_session, user_id=1)
    assert all_res["count"] == 2
    assert any(j["role_title"] == "Google SRE" for j in all_res["jobs"])
    assert any(j["role_title"] == "Stripe Backend Engineer" for j in all_res["jobs"])


def test_get_high_match_jobs(db_session):
    a1 = JdAnalysis(
        user_id=1,
        role_title="Senior Python Lead",
        match_score=85,
        overall_score=82,
        resume_filename="resume.pdf",
    )
    a2 = JdAnalysis(
        user_id=1,
        role_title="Junior Frontend",
        match_score=40,
        overall_score=45,
        resume_filename="resume.pdf",
    )
    db_session.add_all([a1, a2])
    db_session.commit()

    result = get_high_match_jobs(db_session, user_id=1, min_score=50)
    assert result["count"] == 1
    assert result["jobs"][0]["role_title"] == "Senior Python Lead"
    assert result["jobs"][0]["match_score"] == 85


def test_get_overall_standing(db_session):
    a1 = JdAnalysis(
        user_id=1,
        role_title="Role A",
        match_score=80,
        resume_filename="resume.pdf",
    )
    a2 = JdAnalysis(
        user_id=1,
        role_title="Role B",
        match_score=60,
        resume_filename="resume.pdf",
    )
    db_session.add_all([a1, a2])
    db_session.commit()

    standing = get_overall_standing(db_session, user_id=1)
    assert standing["total_analyzed"] == 2
    assert standing["average_score"] == 70.0
    assert standing["highest_score"] == 80
    assert standing["lowest_score"] == 60
    assert standing["jobs_above_50_percent"] == 2


def test_execute_career_tool(db_session):
    tool_res = execute_career_tool("get_overall_standing", {}, db_session, user_id=1)
    assert "average_score" in tool_res


def test_get_today_applied_jobs(db_session):
    today = date.today()
    # 1. JdAnalysis marked applied
    a1 = JdAnalysis(
        user_id=1,
        role_title="Backend Software Engineer",
        match_score=85,
        resume_filename="resume.pdf",
        application_status="applied",
    )
    # 2. JdAnalysis marked not_applied
    a2 = JdAnalysis(
        user_id=1,
        role_title="Frontend Developer",
        match_score=50,
        resume_filename="resume.pdf",
        application_status="not_applied",
    )
    # 3. FollowUp applied today
    f1 = FollowUp(
        user_id=1,
        report_title="Stripe - Senior Python Lead",
        resume_filename="resume.pdf",
        application_date=today,
        follow_up_after_days=3,
        follow_up_date=today + timedelta(days=3),
    )
    db_session.add_all([a1, a2, f1])
    db_session.commit()

    applied_data = get_today_applied_jobs(db_session, user_id=1)
    assert applied_data["count"] == 2
    titles = [j["role_title"] for j in applied_data["jobs"]]
    assert "Backend Software Engineer" in titles
    assert "Stripe - Senior Python Lead" in titles
    assert "Frontend Developer" not in titles

    tool_res = execute_career_tool("get_today_applied_jobs", {}, db_session, user_id=1)
    assert tool_res["count"] == 2

