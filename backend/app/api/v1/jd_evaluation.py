import logging
from fastapi import APIRouter, Depends, HTTPException, status

from app.api.v1.auth import get_current_user
from app.api.v1.resume import UPLOAD_DIR, _safe_filename
from app.models.user import User
from app.schemas.quiz import GenerateQuizRequest, GenerateQuizResponse
from app.services.quiz_agent import QuizAgentError, quiz_agent
from app.services.resume_text import extract_resume_text

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/jd-evaluation", tags=["JD Evaluation"])


@router.post("/generate-quiz", response_model=GenerateQuizResponse)
async def generate_screening_quiz(
    payload: GenerateQuizRequest,
    current_user: User = Depends(get_current_user),
):
    safe_name = _safe_filename(payload.resume_filename)
    resume_path = UPLOAD_DIR / safe_name
    if not resume_path.is_file():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Selected resume file was not found.",
        )

    try:
        resume_text = extract_resume_text(resume_path)
    except Exception as e:
        logger.warning("Could not extract resume text for quiz: %s", e)
        resume_text = ""

    try:
        response = await quiz_agent.generate_quiz(
            resume_text=resume_text,
            job_description=payload.jd_text.strip(),
        )
        return response
    except QuizAgentError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=str(exc),
        ) from exc

