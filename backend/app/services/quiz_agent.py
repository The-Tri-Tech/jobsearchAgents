import asyncio
import json
import logging
from google import genai
from google.genai import errors as gemini_errors, types as gemini_types
from groq import AsyncGroq, APIError as GroqAPIError

from app.core.config import settings
from app.schemas.quiz import GenerateQuizResponse, QuizQuestionItem

logger = logging.getLogger(__name__)

_RETRYABLE_STATUS_CODES = {429, 500, 502, 503, 504}


class QuizAgentError(RuntimeError):
    pass


class QuizAgent:
    """Generates dynamic candidate screening quizzes using Groq or Gemini."""

    async def generate_quiz(
        self,
        *,
        resume_text: str,
        job_description: str,
    ) -> GenerateQuizResponse:
        system_prompt = (
            "You are SkillBridge's technical screening exam agent. "
            "Based on the provided Job Description and candidate Resume, generate exactly 5 realistic, multiple-choice questions "
            "evaluating whether the candidate meets the core technical and practical requirements for this role. "
            "Return strictly a JSON object with this structure:\n"
            "{\n"
            '  "role_title": "<target job role title>",\n'
            '  "questions": [\n'
            "    {\n"
            '      "id": 1,\n'
            '      "question": "<clear technical or situational scenario question>",\n'
            '      "options": ["<option A>", "<option B>", "<option C>", "<option D>"],\n'
            '      "correct_index": <int 0-3 representing the index of the correct option>,\n'
            '      "explanation": "<concise explanation why this option is correct based on industry standards>"\n'
            "    }\n"
            "  ]\n"
            "}"
        )

        user_prompt = f"""
CANDIDATE RESUME:
<resume>
{resume_text[:6000]}
</resume>

TARGET JOB DESCRIPTION:
<job_description>
{job_description[:8000]}
</job_description>
""".strip()

        if settings.LLM_PROVIDER == "groq" and settings.GROQ_API_KEY:
            return await self._generate_groq(system_prompt, user_prompt)
        elif settings.GEMINI_API_KEY:
            return await self._generate_gemini(system_prompt, user_prompt)
        else:
            return self._fallback_quiz()

    async def _generate_groq(self, system_prompt: str, user_prompt: str) -> GenerateQuizResponse:
        client = None
        try:
            client = AsyncGroq(
                api_key=settings.GROQ_API_KEY,
                timeout=settings.GROQ_TIMEOUT_SECONDS,
            )
            response = await client.chat.completions.create(
                model=settings.GROQ_MODEL,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt},
                ],
                temperature=0.3,
                response_format={"type": "json_object"},
            )
            raw = (response.choices[0].message.content or "").strip()
            if raw.startswith("```"):
                raw = raw.split("\n", 1)[-1].rsplit("```", 1)[0].strip()
            return GenerateQuizResponse.model_validate_json(raw)
        except GroqAPIError as exc:
            err_msg = getattr(exc, "message", str(exc))
            logger.warning("Groq quiz generation error: %s", err_msg)
            raise QuizAgentError(f"Groq Quiz error: {err_msg}") from exc
        except Exception as exc:
            logger.exception("Unexpected Groq quiz failure: %s", exc)
            return self._fallback_quiz()
        finally:
            if client is not None:
                await client.close()

    async def _generate_gemini(self, system_prompt: str, user_prompt: str) -> GenerateQuizResponse:
        client = None
        try:
            client = genai.Client(
                api_key=settings.GEMINI_API_KEY,
                http_options=gemini_types.HttpOptions(
                    timeout=int(settings.GEMINI_TIMEOUT_SECONDS * 1000)
                ),
            )
            config = gemini_types.GenerateContentConfig(
                system_instruction=system_prompt,
                temperature=0.3,
                response_mime_type="application/json",
                response_schema=GenerateQuizResponse,
            )
            response = await client.aio.models.generate_content(
                model=settings.GEMINI_MODEL,
                contents=user_prompt,
                config=config,
            )
            if response.parsed:
                return GenerateQuizResponse.model_validate(response.parsed)
            elif response.text:
                raw = response.text.strip()
                if raw.startswith("```"):
                    raw = raw.split("\n", 1)[-1].rsplit("```", 1)[0].strip()
                return GenerateQuizResponse.model_validate_json(raw)
            return self._fallback_quiz()
        except Exception as exc:
            logger.warning("Gemini quiz generation error: %s", exc)
            return self._fallback_quiz()
        finally:
            if client is not None:
                await client.aio.aclose()

    def _fallback_quiz(self) -> GenerateQuizResponse:
        return GenerateQuizResponse(
            role_title="Software Developer",
            questions=[
                QuizQuestionItem(
                    id=1,
                    question="Which data structure provides O(1) average-time complexity for key lookups?",
                    options=["Binary Search Tree", "Hash Map / Dictionary", "Linked List", "Sorted Array"],
                    correct_index=1,
                    explanation="Hash Maps use a hashing function to map keys to bucket indices, providing O(1) average lookup time.",
                ),
                QuizQuestionItem(
                    id=2,
                    question="In RESTful API design, which HTTP method should be used to update an existing resource idempotently?",
                    options=["POST", "PUT", "CONNECT", "TRACE"],
                    correct_index=1,
                    explanation="PUT replaces the target resource with request payload and is defined as idempotent by the HTTP standard.",
                ),
                QuizQuestionItem(
                    id=3,
                    question="Which Git command creates and switches to a new branch in a single step?",
                    options=["git branch -m", "git checkout -b", "git merge --new", "git commit -b"],
                    correct_index=1,
                    explanation="'git checkout -b <branch>' creates and immediately checks out the new branch.",
                ),
                QuizQuestionItem(
                    id=4,
                    question="What is the primary benefit of database indexing on frequently queried columns?",
                    options=["Reduces disk storage", "Improves data query retrieval speed", "Ensures relational cascades", "Prevents SQL injection"],
                    correct_index=1,
                    explanation="Indexes create ordered lookup trees (e.g. B-Trees) allowing the database to locate rows without full table scans.",
                ),
                QuizQuestionItem(
                    id=5,
                    question="In Docker, what does the EXPOSE instruction in a Dockerfile do?",
                    options=["Publishes the port to the host machine automatically", "Documents which ports the container intends to listen on", "Encrypts traffic on that port", "Opens an external firewall rule"],
                    correct_index=1,
                    explanation="EXPOSE acts as metadata/documentation between the author and the operator; the '-p' flag is required at runtime to publish the port.",
                ),
            ],
        )


quiz_agent = QuizAgent()

