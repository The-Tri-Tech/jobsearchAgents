import asyncio
import logging
from google import genai
from google.genai import errors as gemini_errors, types as gemini_types
from groq import AsyncGroq, APIError as GroqAPIError

from app.core.config import settings
from app.schemas.chat import ChatMessageItem

logger = logging.getLogger(__name__)

_RETRYABLE_STATUS_CODES = {429, 500, 502, 503, 504}


class ChatAgentError(RuntimeError):
    pass


class ChatAgent:
    """Conversational Career Assistant supporting both Gemini and Groq."""

    async def chat(
        self,
        *,
        message: str,
        history: list[ChatMessageItem],
        resume_context: str | None = None,
    ) -> str:
        system_instruction = (
            "You are SkillBridge's AI Career Assistant, a supportive, knowledgeable mentor for job seekers. "
            "You help users with resume improvements, job search strategies, behavioral & technical interview prep, "
            "salary negotiations, and upskilling roadmaps. Keep responses concise, structured (using bullet points where helpful), "
            "candid, and actionable. Do not provide overly long walls of text."
        )
        if resume_context:
            system_instruction += f"\n\nCandidate's resume context:\n{resume_context[:6000]}"

        if settings.LLM_PROVIDER == "groq" and settings.GROQ_API_KEY:
            return await self._chat_groq(
                message=message,
                history=history,
                system_instruction=system_instruction,
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

            response = await client.chat.completions.create(
                model=settings.GROQ_MODEL,
                messages=messages,
                temperature=0.7,
                max_tokens=1024,
            )
            reply = response.choices[0].message.content or ""
            return reply.strip() or "I couldn't generate a response. Please try rephrasing."
        except GroqAPIError as exc:
            status_code = getattr(exc, "status_code", "ERROR")
            err_msg = getattr(exc, "message", str(exc))
            logger.warning("Groq chat error (%s): %s", status_code, err_msg)
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
                temperature=0.7,
                max_output_tokens=1024,
                thinking_config=gemini_types.ThinkingConfig(thinking_level="LOW"),
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

            reply_text = response.text or ""
            return reply_text.strip() or "I couldn't generate a response. Please try rephrasing your question."

        except gemini_errors.APIError as exc:
            logger.warning("Gemini chat error (%s): %s", exc.code, exc.message)
            if exc.code == 503 or "high demand" in str(exc.message).lower():
                return "Our AI servers are experiencing high demand right now. Please try asking again in a few moments."
            raise ChatAgentError(f"AI Assistant error: {exc.message}") from exc
        except TimeoutError as exc:
            logger.warning("Gemini chat timed out")
            return "The request took a little too long. Please try asking a shorter question."
        except Exception as exc:
            logger.exception("Unexpected Gemini chat failure: %s", exc)
            return "Sorry, something unexpected happened while generating the response. Please try again."
        finally:
            if client is not None:
                await client.aio.aclose()


chat_agent = ChatAgent()
