from typing import Literal

from pydantic import BaseModel, Field


class AnalyseRequest(BaseModel):
    jd_text: str | None = None
    jd_url: str | None = None
    resume_filename: str


class MatchedSkill(BaseModel):
    skill: str = Field(min_length=1)
    context: str | None = None


class MissingSkill(BaseModel):
    skill: str = Field(min_length=1)
    importance: Literal["High", "Medium", "Low"] = "Medium"


class RecommendedRole(BaseModel):
    title: str = Field(min_length=1)
    match_score: int = Field(ge=0, le=100)
    reason: str = Field(min_length=1)


class AnalysisReport(BaseModel):
    job_title: str = Field(default="", max_length=120)
    resume_used: str
    jd_source: Literal["url", "text"]
    shortlisting_chance: int = Field(ge=0, le=100)
    matched_skills: list[MatchedSkill] = Field(max_length=15)
    missing_skills: list[MissingSkill] = Field(max_length=15)
    overall_score: int = Field(ge=0, le=100)
    summary_title: str = Field(min_length=1, max_length=160)
    summary_paragraphs: list[str] = Field(min_length=1, max_length=4)
    recommended_roles: list[RecommendedRole] = Field(max_length=6)
