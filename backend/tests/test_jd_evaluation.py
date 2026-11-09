import pytest
from app.schemas.quiz import GenerateQuizRequest, GenerateQuizResponse
from app.services.quiz_agent import QuizAgent, quiz_agent


@pytest.mark.anyio
async def test_quiz_agent_fallback():
    agent = QuizAgent()
    fallback = agent._fallback_quiz()
    assert len(fallback.questions) == 5
    for q in fallback.questions:
        assert len(q.options) == 4
        assert 0 <= q.correct_index <= 3
        assert len(q.explanation) > 0


@pytest.mark.anyio
async def test_quiz_agent_without_keys_returns_fallback(monkeypatch):
    monkeypatch.setattr("app.services.quiz_agent.settings.LLM_PROVIDER", "gemini")
    monkeypatch.setattr("app.services.quiz_agent.settings.GEMINI_API_KEY", "")
    monkeypatch.setattr("app.services.quiz_agent.settings.GROQ_API_KEY", "")

    result = await quiz_agent.generate_quiz(
        resume_text="Experienced Python Developer with FastAPI.",
        job_description="Looking for a Python backend engineer with API design experience.",
    )
    assert isinstance(result, GenerateQuizResponse)
    assert len(result.questions) == 5

