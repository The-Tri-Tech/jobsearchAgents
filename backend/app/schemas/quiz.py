from pydantic import BaseModel, Field


class QuizQuestionItem(BaseModel):
    id: int
    question: str = Field(min_length=5)
    options: list[str] = Field(min_length=4, max_length=4)
    correct_index: int = Field(ge=0, le=3)
    explanation: str = Field(min_length=5)


class GenerateQuizRequest(BaseModel):
    resume_filename: str
    jd_text: str = Field(min_length=10, max_length=20000)


class GenerateQuizResponse(BaseModel):
    role_title: str
    questions: list[QuizQuestionItem]

