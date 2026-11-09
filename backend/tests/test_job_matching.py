import asyncio

import pytest
from docx import Document
from fastapi import HTTPException
from google.genai import errors

from app.api.v1 import jd_matcher
from app.schemas.jd_matcher import AnalyseRequest, AnalysisReport
from app.services.job_matching_agent import (
    JobMatchingAgent,
    JobMatchingError,
    _html_to_text,
    _validate_public_url,
    _analysis_cache,
)
from app.services.resume_text import ResumeExtractionError, extract_resume_text


def _report() -> AnalysisReport:
    return AnalysisReport(
        resume_used="ignored.pdf",
        jd_source="text",
        shortlisting_chance=74,
        matched_skills=[{"skill": "Python", "context": "Used in production"}],
        missing_skills=[{"skill": "Kubernetes", "importance": "High"}],
        overall_score=72,
        summary_title="Strong backend alignment",
        summary_paragraphs=["Good core match.", "Cloud experience should be clearer."],
        recommended_roles=[
            {"title": "Backend Engineer", "match_score": 84, "reason": "Relevant stack"}
        ],
    )


def test_extracts_docx_paragraphs_and_tables(tmp_path):
    path = tmp_path / "resume.docx"
    document = Document()
    document.add_paragraph("Python backend engineer with six years of experience.")
    table = document.add_table(rows=1, cols=2)
    table.cell(0, 0).text = "Skill"
    table.cell(0, 1).text = "FastAPI"
    document.save(path)

    text = extract_resume_text(path)

    assert "Python backend engineer" in text
    assert "Skill | FastAPI" in text


def test_rejects_legacy_doc(tmp_path):
    path = tmp_path / "resume.doc"
    path.write_bytes(b"legacy")

    with pytest.raises(ResumeExtractionError, match="PDF or DOCX"):
        extract_resume_text(path)


def test_agent_requires_api_key(monkeypatch):
    monkeypatch.setattr("app.services.job_matching_agent.settings.GEMINI_API_KEY", None)

    with pytest.raises(JobMatchingError, match="GEMINI_API_KEY"):
        asyncio.run(
            JobMatchingAgent().analyse(
                resume_text="A" * 100,
                job_description="B" * 100,
                resume_filename="resume.pdf",
                jd_source="text",
            )
        )


def test_agent_validates_structured_response(monkeypatch):
    closed = False

    class FakeModels:
        async def generate_content(self, **kwargs):
            assert kwargs["model"] == "gemini-test"
            assert "Python resume" in kwargs["contents"]
            return type("Response", (), {"parsed": _report().model_dump(), "text": None})()

    class FakeAsyncClient:
        models = FakeModels()

        async def aclose(self):
            nonlocal closed
            closed = True

    class FakeClient:
        aio = FakeAsyncClient()

    monkeypatch.setattr("app.services.job_matching_agent.settings.GEMINI_API_KEY", "test-key")
    monkeypatch.setattr("app.services.job_matching_agent.settings.GEMINI_MODEL", "gemini-test")
    monkeypatch.setattr("app.services.job_matching_agent.genai.Client", lambda **_: FakeClient())

    result = asyncio.run(
        JobMatchingAgent().analyse(
            resume_text="Python resume " * 10,
            job_description="Backend job " * 10,
            resume_filename="chosen.pdf",
            jd_source="url",
        )
    )

    assert result.resume_used == "chosen.pdf"
    assert result.jd_source == "url"
    assert result.overall_score == 72
    assert closed


def test_agent_times_out_and_closes_client(monkeypatch):
    closed = False

    class SlowModels:
        async def generate_content(self, **kwargs):
            await asyncio.sleep(1)

    class FakeAsyncClient:
        models = SlowModels()

        async def aclose(self):
            nonlocal closed
            closed = True

    class FakeClient:
        aio = FakeAsyncClient()

    monkeypatch.setattr("app.services.job_matching_agent.settings.GEMINI_API_KEY", "test-key")
    monkeypatch.setattr("app.services.job_matching_agent.settings.JOB_MATCH_TIMEOUT_SECONDS", 0.01)
    monkeypatch.setattr("app.services.job_matching_agent.genai.Client", lambda **_: FakeClient())

    with pytest.raises(JobMatchingError, match="did not respond"):
        asyncio.run(
            JobMatchingAgent().analyse(
                resume_text="Python resume " * 10,
                job_description="Backend job " * 10,
                resume_filename="chosen.pdf",
                jd_source="text",
            )
        )

    assert closed


def test_agent_retries_transient_failure_and_caches_success(monkeypatch):
    calls = 0

    class FlakyModels:
        async def generate_content(self, **kwargs):
            nonlocal calls
            calls += 1
            if calls == 1:
                raise errors.ServerError(
                    503,
                    {"error": {"code": 503, "message": "high demand"}},
                )
            return type("Response", (), {"parsed": _report().model_dump(), "text": None})()

    class FakeAsyncClient:
        models = FlakyModels()

        async def aclose(self):
            pass

    class FakeClient:
        aio = FakeAsyncClient()

    async def no_delay(_):
        pass

    _analysis_cache.clear()
    monkeypatch.setattr("app.services.job_matching_agent.settings.GEMINI_API_KEY", "test-key")
    monkeypatch.setattr("app.services.job_matching_agent.settings.GEMINI_MODEL", "retry-test")
    monkeypatch.setattr("app.services.job_matching_agent.genai.Client", lambda **_: FakeClient())
    monkeypatch.setattr("app.services.job_matching_agent.asyncio.sleep", no_delay)
    agent = JobMatchingAgent()
    arguments = {
        "resume_text": "Retry cache resume " * 10,
        "job_description": "Retry cache job " * 10,
        "resume_filename": "chosen.pdf",
        "jd_source": "text",
    }

    first = asyncio.run(agent.analyse(**arguments))
    second = asyncio.run(agent.analyse(**arguments))

    assert first.overall_score == second.overall_score == 72
    assert calls == 2  # one failed attempt + one success; cached call uses no API


def test_url_safety_and_html_cleanup():
    with pytest.raises(JobMatchingError, match="Private or local"):
        _validate_public_url("http://127.0.0.1/internal")

    assert _html_to_text("<h1>Python &amp; APIs</h1><script>ignore()</script>") == "Python & APIs"


def test_validate_jd_url_rejects_linkedin_and_invalid():
    with pytest.raises(HTTPException) as exc1:
        jd_matcher.validate_jd_url("https://www.linkedin.com/jobs/view/123456")
    assert exc1.value.status_code == 422
    assert "LinkedIn" in exc1.value.detail

    with pytest.raises(HTTPException) as exc2:
        jd_matcher.validate_jd_url("not-a-valid-url")
    assert exc2.value.status_code == 422

    normalized = jd_matcher.validate_jd_url("careers.google.com/jobs/results/123")
    assert normalized == "https://careers.google.com/jobs/results/123"


def test_endpoint_uses_selected_resume_and_agent(tmp_path, monkeypatch):
    resume = tmp_path / "selected(1).docx"
    document = Document()
    document.add_paragraph("Python backend engineer with FastAPI and PostgreSQL experience.")
    document.save(resume)

    class FakeAgent:
        async def analyse(self, **kwargs):
            assert kwargs["resume_filename"] == "selected(1).docx"
            assert "FastAPI" in kwargs["resume_text"]
            assert "Senior Python Engineer" in kwargs["job_description"]
            return _report().model_copy(
                update={"resume_used": kwargs["resume_filename"]}
            )

    monkeypatch.setattr(jd_matcher, "UPLOAD_DIR", tmp_path)
    monkeypatch.setattr(jd_matcher, "job_matching_agent", FakeAgent())
    monkeypatch.setattr(jd_matcher.settings, "APP_ENV", "test")
    monkeypatch.setattr(jd_matcher.settings, "LLM_PROVIDER", "gemini")

    result = asyncio.run(
        jd_matcher.analyse_jd(
            AnalyseRequest(
                jd_text="Senior Python Engineer " + "with API experience " * 5,
                resume_filename="selected(1).docx",
            ),
            current_user=object(),
        )
    )

    assert result.resume_used == "selected(1).docx"
    assert result.overall_score == 72


def test_endpoint_rejects_missing_resume(tmp_path, monkeypatch):
    monkeypatch.setattr(jd_matcher, "UPLOAD_DIR", tmp_path)

    with pytest.raises(HTTPException) as exc_info:
        asyncio.run(
            jd_matcher.analyse_jd(
                AnalyseRequest(jd_text="A valid job description", resume_filename="missing.pdf"),
                current_user=object(),
            )
        )

    assert exc_info.value.status_code == 404


def test_development_mode_returns_mock_without_calling_agent(tmp_path, monkeypatch):
    resume = tmp_path / "development.pdf"
    resume.write_bytes(b"mock mode does not need to parse this document")

    class FailingAgent:
        async def analyse(self, **kwargs):
            raise AssertionError("Gemini must not be called in development mode")

    monkeypatch.setattr(jd_matcher, "UPLOAD_DIR", tmp_path)
    monkeypatch.setattr(jd_matcher, "job_matching_agent", FailingAgent())
    monkeypatch.setattr(jd_matcher.settings, "APP_ENV", "development")

    result = asyncio.run(
        jd_matcher.analyse_jd(
            AnalyseRequest(
                jd_text="A development job description",
                resume_filename="development.pdf",
            ),
            current_user=object(),
        )
    )

    assert result.resume_used == "development.pdf"
    assert result.overall_score == 72


def test_endpoint_uses_groq_when_provider_is_groq(tmp_path, monkeypatch):
    resume = tmp_path / "resume_groq.docx"
    document = Document()
    document.add_paragraph("Fullstack Python and React developer with five years of experience building scalable backend APIs.")
    document.save(resume)

    class FakeGroqAgent:
        async def analyse(self, **kwargs):
            assert kwargs["resume_filename"] == "resume_groq.docx"
            return _report().model_copy(
                update={"resume_used": kwargs["resume_filename"], "summary_title": "Analyzed by Groq"}
            )

    monkeypatch.setattr(jd_matcher, "UPLOAD_DIR", tmp_path)
    monkeypatch.setattr(jd_matcher, "groq_matching_agent", FakeGroqAgent())
    monkeypatch.setattr(jd_matcher.settings, "APP_ENV", "test")
    monkeypatch.setattr(jd_matcher.settings, "LLM_PROVIDER", "groq")

    result = asyncio.run(
        jd_matcher.analyse_jd(
            AnalyseRequest(
                jd_text="Fullstack Developer with Python and React experience " * 5,
                resume_filename="resume_groq.docx",
            ),
            current_user=object(),
        )
    )

    assert result.resume_used == "resume_groq.docx"
    assert result.summary_title == "Analyzed by Groq"

