import asyncio
import json
import logging
import re
from google import genai
from google.genai import errors as gemini_errors, types as gemini_types
from groq import AsyncGroq, APIError as GroqAPIError
from sqlalchemy.orm import Session

from app.core.config import settings
from app.schemas.chat import ChatMessageItem
from app.services.career_tools import (
    CAREER_TOOLS_SCHEMA,
    execute_career_tool,
    get_high_match_jobs,
    get_overall_standing,
    get_today_follow_ups,
)

logger = logging.getLogger(__name__)

_RETRYABLE_STATUS_CODES = {429, 500, 502, 503, 504}


class ChatAgentError(RuntimeError):
    pass


def check_career_guardrails(message: str) -> str | None:
    """
    Enforces strict domain guardrails: only questions related to jobs, careers,
    resumes, interviews, and user application statistics are allowed.
    Returns a refusal string if off-topic, or None if the message is in-scope.
    """
    lower = message.strip().lower()

    # Allow basic greetings and polite conversation starters
    greetings = {
        "hi", "hello", "hey", "good morning", "good evening", "good afternoon",
        "help", "who are you", "what can you do", "thanks", "thank you", "bye"
    }
    if lower in greetings or any(lower.startswith(g) for g in ["hi ", "hello ", "hey "]):
        return None

    # Off-topic domain patterns
    off_topic_patterns = [
        r"\brecipe\b", r"\bcook\b", r"\bbake\b", r"\bpasta\b", r"\bpizza\b",
        r"\bmovie\b", r"\bcelebrity\b", r"\bhollywood\b", r"\bbollywood\b",
        r"\bfootball\b", r"\bcricket\b", r"\bbasketball\b", r"\bweather\b",
        r"\bhoroscope\b", r"\bzodiac\b", r"\bgaming\b", r"\bfortnite\b",
        r"\bpolitics\b", r"\belection\b", r"\bpresident\b", r"\bjoke\b",
        r"\bpoem\b", r"\bsong\b", r"\blyrics\b",
    ]

    for pat in off_topic_patterns:
        if re.search(pat, lower):
            career_terms = [
                r"\bjobs?\b", r"\bcareers?\b", r"\binterviews?\b", r"\bresumes?\b",
                r"\bwork\b", r"\bapply\b", r"\bapplied\b", r"\bapplications?\b",
                r"\bcompan(y|ies)\b", r"\bhiring\b", r"\bfollow[\s-]?ups?\b",
                r"\bmatch(es)?\b", r"\bscores?\b", r"\bskills?\b", r"\bats\b",
                r"\bsalar(y|ies)\b",
            ]
            if not any(re.search(term, lower) for term in career_terms):
                return (
                    "I am your dedicated SkillBridge Career Assistant. I can only assist with your "
                    "job search, career development, interview preparation, resume reviews, and personal "
                    "application statistics. Please ask me questions related to your career or jobs!"
                )

    return None


class ChatAgent:
    """Conversational Career Assistant with strict guardrails and MCP tools."""

    async def chat(
        self,
        *,
        message: str,
        history: list[ChatMessageItem],
        resume_context: str | None = None,
        db: Session | None = None,
        user_id: int | None = None,
    ) -> str:
        # 1. Guardrail Check
        guardrail_refusal = check_career_guardrails(message)
        if guardrail_refusal:
            return guardrail_refusal

        # 2. System Instructions
        system_instruction = (
            "You are SkillBridge's AI Career Assistant, a supportive, knowledgeable mentor for job seekers.\n\n"
            "STRICT GUARDRAILS & SCOPE OF ASSISTANCE:\n"
            "1. You must ONLY answer questions directly related to jobs, careers, job searching, resumes, interviews, "
            "professional skills, salary negotiation, and the user's specific application data, follow-ups, and match scores.\n"
            "2. If the user asks about ANY topic outside of jobs, careers, or their profile (for example: cooking, movie trivia, "
            "politics, sports, general entertainment, creative writing, or non-career general knowledge), politely and firmly refuse to answer. "
            "Explain that you are exclusively focused on helping them with their career and job search, and guide them back to asking about their applications or career goals.\n\n"
            "STYLE:\n"
            "Keep responses concise, structured (using bullet points where helpful), candid, and actionable. Do not provide overly long walls of text."
        )

        if resume_context:
            system_instruction += f"\n\nCandidate's resume context:\n{resume_context[:6000]}"

        # 3. Grounding with Tool Context (Deterministic Intent Dispatch)
        tool_context_str = ""
        if db is not None and user_id is not None:
            lower = message.lower()
            if any(k in lower for k in ["follow up", "follow-up", "followup", "need to follow"]):
                data = get_today_follow_ups(db, user_id)
                tool_context_str += f"\n[DATABASE TOOL RESULT - Today's Follow-Ups: {json.dumps(data)}]"

            if any(k in lower for k in ["greater than 50", "> 50", "score greater", "suit me score", "suit me", "above 50"]):
                data = get_high_match_jobs(db, user_id, min_score=50)
                tool_context_str += f"\n[DATABASE TOOL RESULT - Jobs with Match Score > 50%: {json.dumps(data)}]"

            if any(k in lower for k in ["how am i doing", "how i am doing", "overall", "average score", "avg of all scores", "overall standing"]):
                data = get_overall_standing(db, user_id)
                tool_context_str += f"\n[DATABASE TOOL RESULT - Overall Career Standing & Averages: {json.dumps(data)}]"

        if tool_context_str:
            system_instruction += (
                f"\n\nLIVE DATABASE CONTEXT (Verified user data from backend MCP tools):\n{tool_context_str}\n"
                "Use this exact data to answer the user's question accurately without guessing or hallucinating numbers."
            )

        if settings.LLM_PROVIDER == "groq" and settings.GROQ_API_KEY:
            return await self._chat_groq(
                message=message,
                history=history,
                system_instruction=system_instruction,
                db=db,
                user_id=user_id,
            )
        elif settings.GEMINI_API_KEY:
            return await self._chat_gemini(
                message=message,
                history=history,
                system_instruction=system_instruction,
            )
        else:
            return (
                "I am your AI Career Assistant. To enable live AI intelligence, "
                f"please set {'GROQ_API_KEY' if settings.LLM_PROVIDER == 'groq' else 'GEMINI_API_KEY'} in backend/.env."
            )

    async def _chat_groq(
        self,
        *,
        message: str,
        history: list[ChatMessageItem],
        system_instruction: str,
        db: Session | None = None,
        user_id: int | None = None,
    ) -> str:
        client = None
        try:
            client = AsyncGroq(
                api_key=settings.GROQ_API_KEY,
                timeout=settings.GROQ_TIMEOUT_SECONDS,
            )
            messages = [{"role": "system", "content": system_instruction}]
            for item in history[-10:]:
                role = "assistant" if item.role == "assistant" else "user"
                messages.append({"role": role, "content": item.content})
            messages.append({"role": "user", "content": message})

            # Call Groq with career tools enabled
            response = await client.chat.completions.create(
                model=settings.GROQ_MODEL,
                messages=messages,
                tools=CAREER_TOOLS_SCHEMA,
                tool_choice="auto",
                temperature=0.4,
                max_tokens=1024,
            )

            choice = response.choices[0]
            if choice.message.tool_calls and db is not None and user_id is not None:
                # Execute tool call and continue
                tool_call = choice.message.tool_calls[0]
                tool_name = tool_call.function.name
                try:
                    tool_args = json.loads(tool_call.function.arguments or "{}")
                except Exception:
                    tool_args = {}

                tool_result = execute_career_tool(tool_name, tool_args, db, user_id)
                messages.append(choice.message)
                messages.append({
                    "role": "tool",
                    "tool_call_id": tool_call.id,
                    "content": json.dumps(tool_result),
                })

                # Follow-up completion with tool output
                second_response = await client.chat.completions.create(
                    model=settings.GROQ_MODEL,
                    messages=messages,
                    temperature=0.4,
                    max_tokens=1024,
                )
                reply = second_response.choices[0].message.content or ""
                return reply.strip() or "I have processed your query."

            reply = choice.message.content or ""
            return reply.strip() or "I couldn't generate a response. Please try rephrasing."
        except GroqAPIError as exc:
            err_msg = getattr(exc, "message", str(exc))
            logger.warning("Groq chat error: %s", err_msg)
            raise ChatAgentError(f"Groq Chat Assistant error: {err_msg}") from exc
        except Exception as exc:
            logger.exception("Unexpected Groq chat failure: %s", exc)
            return "Sorry, something unexpected happened while generating the response via Groq. Please try again."
        finally:
            if client is not None:
                await client.close()

    async def _chat_gemini(
        self,
        *,
        message: str,
        history: list[ChatMessageItem],
        system_instruction: str,
    ) -> str:
        client = None
        try:
            client = genai.Client(
                api_key=settings.GEMINI_API_KEY,
                http_options=gemini_types.HttpOptions(
                    timeout=int(settings.GEMINI_TIMEOUT_SECONDS * 1000)
                ),
            )
            contents: list[gemini_types.Content] = []
            for item in history[-10:]:
                role = "user" if item.role == "user" else "model"
                contents.append(
                    gemini_types.Content(
                        role=role,
                        parts=[gemini_types.Part.from_text(text=item.content)],
                    )
                )
            contents.append(
                gemini_types.Content(
                    role="user",
                    parts=[gemini_types.Part.from_text(text=message)],
                )
            )

            config = gemini_types.GenerateContentConfig(
                system_instruction=system_instruction,
                temperature=0.4,
                max_output_tokens=1024,
            )

            delays = [2, 4, 8]
            for attempt in range(4):
                try:
                    response = await client.aio.models.generate_content(
                        model=settings.GEMINI_MODEL,
                        contents=contents,
                        config=config,
                    )
                    break
                except gemini_errors.APIError as exc:
                    if exc.code not in _RETRYABLE_STATUS_CODES or attempt == 3:
                        raise
                    delay = delays[attempt]
                    logger.warning(
                        "Retryable Gemini error %s in chat; retrying in %ss (attempt %s/4)",
                        exc.code,
                        delay,
                        attempt + 2,
                    )
                    await asyncio.sleep(delay)

            return (response.text or "").strip() or "I couldn't generate a response. Please try rephrasing."
        except Exception as exc:
            logger.exception("Gemini chat error: %s", exc)
            return "Sorry, something unexpected happened with the Gemini Assistant. Please try again."
        finally:
            if client is not None:
                await client.aio.aclose()


chat_agent = ChatAgent()
