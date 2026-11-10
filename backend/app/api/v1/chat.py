import logging
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.v1.auth import get_current_user
from app.api.v1.resume import UPLOAD_DIR, _safe_filename
from app.db.session import get_db
from app.models.user import User
from app.schemas.chat import ChatRequest, ChatResponse
from app.services.chat_agent import ChatAgentError, chat_agent
from app.services.resume_text import extract_resume_text

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/chat", tags=["Chat"])


@router.post("", response_model=ChatResponse)
async def send_chat_message(
    payload: ChatRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    resume_context = None
    if payload.resume_filename:
        safe_name = _safe_filename(payload.resume_filename)
        resume_path = UPLOAD_DIR / safe_name
        if resume_path.is_file():
            try:
                resume_context = extract_resume_text(resume_path)
            except Exception as e:
                logger.warning("Could not extract resume for chat context: %s", e)

    try:
        agent_res = await chat_agent.chat(
            message=payload.message.strip(),
            history=payload.history,
            resume_context=resume_context,
            db=db,
            user_id=current_user.id,
        )
        return ChatResponse(reply=agent_res.reply, tool_called=agent_res.tool_called)
    except ChatAgentError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=str(exc),
        ) from exc

