from typing import List, Optional
from pydantic import BaseModel
from fastapi import APIRouter, Depends, HTTPException, status
from app.api.v1.auth import get_current_user
from app.models.user import User

router = APIRouter(prefix="/jd-matcher", tags=["JD Matcher"])


# ── Request / Response schemas ────────────────────────────────────────────────

class AnalyseRequest(BaseModel):
    jd_text: Optional[str] = None      # full JD pasted by user
    jd_url: Optional[str] = None       # URL of the JD page
    resume_filename: str               # which resume to match against


class MatchedSkill(BaseModel):
    skill: str
    context: Optional[str] = None


class MissingSkill(BaseModel):
    skill: str
    importance: str = "Medium"         # High / Medium / Low


class RecommendedRole(BaseModel):
    title: str
    match_score: int
    reason: str


class AnalysisReport(BaseModel):
    resume_used: str
    jd_source: str                     # "url" | "text"
    shortlisting_chance: int           # 0-100 %

    # Section 1 – skills gap
    matched_skills: List[MatchedSkill]
    missing_skills: List[MissingSkill]

    # Section 2 – summary
    overall_score: int
    summary_title: str
    summary_paragraphs: List[str]

    # Section 3 – recommended roles
    recommended_roles: List[RecommendedRole]


# ── Mock data ─────────────────────────────────────────────────────────────────

def _mock_report(resume_filename: str, jd_source: str) -> AnalysisReport:
    """Return deterministic mock data so the UI flow can be tested end-to-end."""
    return AnalysisReport(
        resume_used=resume_filename,
        jd_source=jd_source,
        shortlisting_chance=72,
        matched_skills=[
            MatchedSkill(skill="Python", context="5+ years, mentioned 4 times in JD"),
            MatchedSkill(skill="FastAPI", context="Exact framework match"),
            MatchedSkill(skill="REST APIs", context="Demonstrated in multiple projects"),
            MatchedSkill(skill="SQL / PostgreSQL", context="Aligns with JD requirement"),
            MatchedSkill(skill="Docker", context="Containerisation experience matched"),
            MatchedSkill(skill="Git & CI/CD", context="Version control experience found"),
            MatchedSkill(skill="Agile / Scrum", context="Mentioned in work experience"),
        ],
        missing_skills=[
            MissingSkill(skill="Kubernetes", importance="High"),
            MissingSkill(skill="AWS / Cloud deployment", importance="High"),
            MissingSkill(skill="GraphQL", importance="Medium"),
            MissingSkill(skill="Redis / Caching", importance="Medium"),
            MissingSkill(skill="Terraform (IaC)", importance="Low"),
        ],
        overall_score=72,
        summary_title="Strong Backend Developer Profile — Cloud Gaps Present",
        summary_paragraphs=[
            (
                "Your resume demonstrates solid backend engineering fundamentals with Python and FastAPI, "
                "which are core requirements for this role. Your hands-on experience with REST API design, "
                "SQL databases, and Docker containerisation aligns well with roughly 70% of the technical "
                "criteria outlined in the job description."
            ),
            (
                "However, the role places significant emphasis on cloud-native deployment — particularly "
                "Kubernetes orchestration and AWS services — which are not prominently featured in your "
                "current resume. Bridging these gaps would meaningfully increase your shortlisting chances."
            ),
            (
                "Overall, you are a competitive candidate for mid-level backend positions. With targeted "
                "upskilling in cloud infrastructure and a minor revision to highlight CI/CD pipelines, "
                "your profile would be well-positioned for this and similar senior roles."
            ),
        ],
        recommended_roles=[
            RecommendedRole(
                title="Backend Engineer (Python)",
                match_score=88,
                reason="Your Python + FastAPI + REST API experience is a near-perfect fit for this category.",
            ),
            RecommendedRole(
                title="API Platform Developer",
                match_score=81,
                reason="Strong overlap in API design patterns and database work.",
            ),
            RecommendedRole(
                title="Full-Stack Engineer (Python + React)",
                match_score=70,
                reason="Backend skills are strong; adding frontend experience would open this path further.",
            ),
            RecommendedRole(
                title="DevOps / Platform Engineer",
                match_score=55,
                reason="Docker and CI/CD knowledge is a good foundation; cloud skills need development.",
            ),
        ],
    )


# ── Endpoint ──────────────────────────────────────────────────────────────────

@router.post("/analyse", response_model=AnalysisReport)
def analyse_jd(
    payload: AnalyseRequest,
    current_user: User = Depends(get_current_user),
):
    if not payload.jd_text and not payload.jd_url:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Provide either 'jd_text' or 'jd_url'.",
        )
    if not payload.resume_filename:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="'resume_filename' is required.",
        )

    jd_source = "url" if payload.jd_url else "text"
    return _mock_report(payload.resume_filename, jd_source)
