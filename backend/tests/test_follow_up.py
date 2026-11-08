from datetime import date
from types import SimpleNamespace
from unittest.mock import MagicMock

from app.api.v1.follow_up import create_follow_up
from app.schemas.follow_up import FollowUpCreate


def test_create_follow_up_calculates_due_date_and_owner():
    db = MagicMock()
    payload = FollowUpCreate(
        report_title="Strong Python match",
        resume_filename="resume.pdf",
        application_date=date(2026, 11, 8),
        follow_up_after_days=5,
    )

    result = create_follow_up(
        payload,
        current_user=SimpleNamespace(id=42),
        db=db,
    )

    assert result.user_id == 42
    assert result.follow_up_date == date(2026, 11, 13)
    assert result.status == "pending"
    db.add.assert_called_once_with(result)
    db.commit.assert_called_once()
    db.refresh.assert_called_once_with(result)
