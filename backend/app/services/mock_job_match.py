from app.schemas.jd_matcher import AnalysisReport


def mock_job_match_report(resume_filename: str, jd_source: str) -> AnalysisReport:
    """Return deterministic development data without calling Gemini."""
    return AnalysisReport(
        resume_used=resume_filename,
        jd_source=jd_source,
        shortlisting_chance=72,
        matched_skills=[
            {"skill": "Python", "context": "Demonstrated in resume projects and experience"},
            {"skill": "FastAPI", "context": "Direct framework match"},
            {"skill": "REST APIs", "context": "Relevant API development experience"},
            {"skill": "PostgreSQL", "context": "Database experience aligns with the role"},
            {"skill": "Git", "context": "Version-control experience found"},
        ],
        missing_skills=[
            {"skill": "Kubernetes", "importance": "High"},
            {"skill": "Cloud deployment", "importance": "High"},
            {"skill": "Redis", "importance": "Medium"},
        ],
        overall_score=72,
        summary_title="Strong Backend Profile — Cloud Skills Need More Evidence",
        summary_paragraphs=[
            "Your resume shows relevant Python backend and API development experience that aligns with the core requirements of this role.",
            "The largest gaps are cloud-native deployment and infrastructure skills. Highlighting production deployments or adding relevant projects would strengthen the match.",
        ],
        recommended_roles=[
            {
                "title": "Python Backend Engineer",
                "match_score": 86,
                "reason": "Strong alignment across Python, APIs, and relational databases.",
            },
            {
                "title": "API Platform Developer",
                "match_score": 79,
                "reason": "The resume demonstrates relevant service and API development skills.",
            },
            {
                "title": "Full-Stack Python Engineer",
                "match_score": 68,
                "reason": "Backend alignment is strong; more frontend evidence would improve the fit.",
            },
        ],
    )
